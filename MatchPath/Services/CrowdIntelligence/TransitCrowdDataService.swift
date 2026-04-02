import Foundation
import CoreLocation

/// Service to get crowd intelligence from public transit data
/// Uses Transit Land API (free) to detect crowding patterns
class TransitCrowdDataService {

    // MARK: - Properties

    private let baseURL = "https://transit.land/api/v2/rest"

    // MARK: - Public Methods

    /// Get crowd level based on transit congestion near a stadium
    func getTransitBasedCrowdLevel(
        near coordinate: Coordinate,
        radiusMeters: Int = 1000
    ) async throws -> TransitCrowdData {

        // Step 1: Find transit stops near stadium
        let stops = try await findNearbyStops(
            lat: coordinate.latitude,
            lon: coordinate.longitude,
            radius: radiusMeters
        )

        print("🚇 TransitCrowd: Found \(stops.count) transit stops near stadium")

        guard !stops.isEmpty else {
            throw TransitError.noStopsFound
        }

        // Step 2: Get real-time departure data for each stop
        var totalDelay: Int = 0
        var departureCount: Int = 0
        var delayedRoutes: Int = 0

        for stop in stops.prefix(5) {  // Check top 5 closest stops
            if let departures = try? await getDepartures(stopId: stop.onestopId) {
                for departure in departures {
                    if let delay = departure.delay {
                        totalDelay += delay
                        departureCount += 1

                        if delay > 120 {  // More than 2 min late
                            delayedRoutes += 1
                        }
                    }
                }
            }
        }

        // Step 3: Calculate crowd level from delay patterns
        let avgDelay = departureCount > 0 ? Double(totalDelay) / Double(departureCount) : 0
        let crowdScore = calculateCrowdScore(
            averageDelay: avgDelay,
            delayedRouteCount: delayedRoutes,
            totalDepartures: departureCount
        )

        print("🚇 TransitCrowd: Avg delay: \(avgDelay)s, Delayed routes: \(delayedRoutes)")
        print("🚇 TransitCrowd: Crowd score: \(crowdScore)")

        return TransitCrowdData(
            crowdLevel: crowdLevel(from: crowdScore),
            averageDelaySeconds: Int(avgDelay),
            delayedRouteCount: delayedRoutes,
            totalRoutesChecked: departureCount,
            confidence: calculateConfidence(departureCount: departureCount),
            reasoning: generateReasoning(
                avgDelay: avgDelay,
                delayedRoutes: delayedRoutes,
                totalDepartures: departureCount
            )
        )
    }

    // MARK: - Private Methods

    private func findNearbyStops(
        lat: Double,
        lon: Double,
        radius: Int
    ) async throws -> [TransitStop] {

        let urlString = "\(baseURL)/stops?lat=\(lat)&lon=\(lon)&radius=\(radius)"

        guard let url = URL(string: urlString) else {
            throw TransitError.invalidURL
        }

        print("🚇 TransitCrowd: Fetching stops from: \(urlString)")

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw TransitError.apiError
        }

        let decoder = JSONDecoder()
        let result = try decoder.decode(TransitStopsResponse.self, from: data)

        return result.stops ?? []
    }

    private func getDepartures(stopId: String) async throws -> [Departure] {
        let urlString = "\(baseURL)/stops/\(stopId)/departures"

        guard let url = URL(string: urlString) else {
            throw TransitError.invalidURL
        }

        print("🚇 TransitCrowd: Fetching departures for stop: \(stopId)")

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            print("⚠️ TransitCrowd: Failed to get departures for \(stopId)")
            return []
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let result = try decoder.decode(DeparturesResponse.self, from: data)

        return result.stops?.first?.departures ?? []
    }

    private func calculateCrowdScore(
        averageDelay: Double,
        delayedRouteCount: Int,
        totalDepartures: Int
    ) -> Double {

        var score: Double = 0.0

        // Factor 1: Average delay (0-1 scale)
        // 0 seconds = 0.0, 300+ seconds = 1.0
        let delayScore = min(averageDelay / 300.0, 1.0)
        score += delayScore * 0.6  // 60% weight

        // Factor 2: Percentage of delayed routes
        if totalDepartures > 0 {
            let delayedPercentage = Double(delayedRouteCount) / Double(totalDepartures)
            score += delayedPercentage * 0.4  // 40% weight
        }

        return min(score, 1.0)
    }

    private func crowdLevel(from score: Double) -> CrowdLevel {
        switch score {
        case 0..<0.3:
            return .clear
        case 0.3..<0.6:
            return .moderate
        case 0.6..<0.8:
            return .crowded
        default:
            return .avoid
        }
    }

    private func calculateConfidence(departureCount: Int) -> Double {
        // More data points = higher confidence
        switch departureCount {
        case 0:
            return 0.0
        case 1...3:
            return 0.5
        case 4...8:
            return 0.75
        default:
            return 0.95
        }
    }

    private func generateReasoning(
        avgDelay: Double,
        delayedRoutes: Int,
        totalDepartures: Int
    ) -> String {

        if totalDepartures == 0 {
            return "No transit data available for this area"
        }

        if avgDelay > 240 {
            return "Transit is significantly delayed (\(Int(avgDelay))s avg). Stadium area is very crowded."
        } else if avgDelay > 120 {
            return "Transit delays detected (\(Int(avgDelay))s avg). Moderate crowds heading to stadium."
        } else if delayedRoutes > totalDepartures / 2 {
            return "\(delayedRoutes) of \(totalDepartures) routes delayed. Crowds building up."
        } else {
            return "Transit running normally. Light crowds expected."
        }
    }
}

// MARK: - Models

struct TransitCrowdData {
    let crowdLevel: CrowdLevel
    let averageDelaySeconds: Int
    let delayedRouteCount: Int
    let totalRoutesChecked: Int
    let confidence: Double  // 0.0 - 1.0
    let reasoning: String
}

// MARK: - Transit Land API Response Models

struct TransitStopsResponse: Codable {
    let stops: [TransitStop]?
}

struct TransitStop: Codable {
    let onestopId: String
    let stopName: String
    let geometry: Geometry

    enum CodingKeys: String, CodingKey {
        case onestopId = "onestop_id"
        case stopName = "stop_name"
        case geometry
    }
}

struct Geometry: Codable {
    let coordinates: [Double]  // [lon, lat]
}

struct DeparturesResponse: Codable {
    let stops: [StopWithDepartures]?
}

struct StopWithDepartures: Codable {
    let departures: [Departure]
}

struct Departure: Codable {
    let trip: Trip?
    let arrival: ArrivalInfo?
    let stopSequence: Int?

    var delay: Int? {
        guard let arrival = arrival,
              let estimated = arrival.estimated,
              let scheduled = arrival.scheduled else {
            return nil
        }

        return Int(estimated.timeIntervalSince(scheduled))
    }

    enum CodingKeys: String, CodingKey {
        case trip
        case arrival
        case stopSequence = "stop_sequence"
    }
}

struct Trip: Codable {
    let tripHeadsign: String?
    let tripId: String?

    enum CodingKeys: String, CodingKey {
        case tripHeadsign = "trip_headsign"
        case tripId = "trip_id"
    }
}

struct ArrivalInfo: Codable {
    let estimated: Date?
    let scheduled: Date?
    let delay: Int?
}

// MARK: - Errors

enum TransitError: Error, LocalizedError {
    case invalidURL
    case apiError
    case noStopsFound
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Transit Land API URL"
        case .apiError:
            return "Transit Land API request failed"
        case .noStopsFound:
            return "No transit stops found near this location"
        case .noData:
            return "No transit data available"
        }
    }
}