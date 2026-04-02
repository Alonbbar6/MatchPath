import Foundation
import CoreLocation

/// Service for getting directions with real-time traffic data using Google Directions API
class GoogleDirectionsService {
    static let shared = GoogleDirectionsService()

    private init() {}

    // MARK: - Public Methods

    /// Get route from origin to destination with traffic-aware travel time
    /// - Parameters:
    ///   - origin: Starting coordinates
    ///   - destination: Destination coordinates
    ///   - departureTime: When the journey will start (for traffic prediction)
    ///   - travelMode: How to travel (transit, driving, walking)
    /// - Returns: Route information with traffic-adjusted duration
    func getRoute(
        from origin: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D,
        departureTime: Date = Date(),
        travelMode: GoogleMapsConfig.TravelMode = .transit
    ) async throws -> RouteInfo {
        let result = try await performDirectionsRequest(
            origin: origin,
            destination: destination,
            departureTime: departureTime,
            travelMode: travelMode,
            alternatives: false
        )

        guard let firstRoute = result.first else {
            throw DirectionsError.noRoutes
        }

        return firstRoute
    }

    /// Get multiple alternative routes with traffic data
    /// - Parameters:
    ///   - origin: Starting coordinates
    ///   - destination: Destination coordinates
    ///   - departureTime: When the journey will start
    ///   - travelMode: How to travel
    /// - Returns: Array of route options, sorted by fastest first
    func getAlternativeRoutes(
        from origin: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D,
        departureTime: Date = Date(),
        travelMode: GoogleMapsConfig.TravelMode = .transit
    ) async throws -> [RouteInfo] {
        return try await performDirectionsRequest(
            origin: origin,
            destination: destination,
            departureTime: departureTime,
            travelMode: travelMode,
            alternatives: true
        )
    }

    // MARK: - Private Methods

    private func performDirectionsRequest(
        origin: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        departureTime: Date,
        travelMode: GoogleMapsConfig.TravelMode,
        alternatives: Bool
    ) async throws -> [RouteInfo] {
        // Build URL with query parameters
        var components = URLComponents(string: GoogleMapsConfig.directionsBaseURL)!

        var queryItems = [
            URLQueryItem(name: "origin", value: "\(origin.latitude),\(origin.longitude)"),
            URLQueryItem(name: "destination", value: "\(destination.latitude),\(destination.longitude)"),
            URLQueryItem(name: "mode", value: travelMode.rawValue),
            URLQueryItem(name: "key", value: GoogleMapsConfig.apiKey)
        ]

        // Add departure time for traffic data
        if GoogleMapsConfig.useTrafficData && travelMode == .driving || travelMode == .transit {
            let timestamp = Int(departureTime.timeIntervalSince1970)
            queryItems.append(URLQueryItem(name: "departure_time", value: "\(timestamp)"))
        }

        // Request alternative routes
        if alternatives {
            queryItems.append(URLQueryItem(name: "alternatives", value: "true"))
        }

        // Enable traffic model for more accurate predictions
        if travelMode == .driving {
            queryItems.append(URLQueryItem(name: "traffic_model", value: "best_guess"))
        }

        components.queryItems = queryItems

        guard let url = components.url else {
            throw DirectionsError.invalidURL
        }

        // Make API request
        let (data, response) = try await URLSession.shared.data(from: url)

        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DirectionsError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw DirectionsError.httpError(statusCode: httpResponse.statusCode)
        }

        // Parse JSON response
        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(DirectionsAPIResponse.self, from: data)

        // Check API status
        guard apiResponse.status == "OK" else {
            throw DirectionsError.apiError(status: apiResponse.status)
        }

        // Convert API routes to RouteInfo
        return apiResponse.routes.map { route in
            let leg = route.legs.first! // Will always have at least one leg

            return RouteInfo(
                summary: route.summary,
                distanceMeters: leg.distance.value,
                distanceText: leg.distance.text,
                durationSeconds: leg.duration.value,
                durationText: leg.duration.text,
                durationInTrafficSeconds: leg.duration_in_traffic?.value ?? leg.duration.value,
                durationInTrafficText: leg.duration_in_traffic?.text ?? leg.duration.text,
                startAddress: leg.start_address,
                endAddress: leg.end_address,
                steps: leg.steps.map { step in
                    RouteStep(
                        instruction: step.html_instructions.stripHTML(),
                        distanceMeters: step.distance.value,
                        durationSeconds: step.duration.value,
                        travelMode: step.travel_mode
                    )
                },
                polyline: route.overview_polyline.points
            )
        }
    }
}

// MARK: - Models

struct RouteInfo {
    let summary: String
    let distanceMeters: Int
    let distanceText: String
    let durationSeconds: Int
    let durationText: String
    let durationInTrafficSeconds: Int
    let durationInTrafficText: String
    let startAddress: String
    let endAddress: String
    let steps: [RouteStep]
    let polyline: String

    /// Travel time in minutes (accounting for traffic)
    var travelTimeMinutes: Int {
        return (durationInTrafficSeconds + 59) / 60 // Round up
    }

    /// Traffic delay in minutes
    var trafficDelayMinutes: Int {
        return max(0, (durationInTrafficSeconds - durationSeconds) / 60)
    }
}

struct RouteStep {
    let instruction: String
    let distanceMeters: Int
    let durationSeconds: Int
    let travelMode: String
}

// MARK: - API Response Models

private struct DirectionsAPIResponse: Codable {
    let routes: [Route]
    let status: String

    struct Route: Codable {
        let summary: String
        let legs: [Leg]
        let overview_polyline: Polyline

        struct Leg: Codable {
            let distance: Distance
            let duration: Duration
            let duration_in_traffic: Duration?
            let start_address: String
            let end_address: String
            let steps: [Step]

            struct Step: Codable {
                let html_instructions: String
                let distance: Distance
                let duration: Duration
                let travel_mode: String
            }
        }

        struct Polyline: Codable {
            let points: String
        }
    }

    struct Distance: Codable {
        let value: Int // meters
        let text: String // human-readable
    }

    struct Duration: Codable {
        let value: Int // seconds
        let text: String // human-readable
    }
}

// MARK: - Errors

enum DirectionsError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case apiError(status: String)
    case noRoutes
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid request URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "Server error: \(code)"
        case .apiError(let status):
            switch status {
            case "NOT_FOUND":
                return "Could not find a route to your destination"
            case "ZERO_RESULTS":
                return "No route available"
            case "MAX_WAYPOINTS_EXCEEDED":
                return "Too many waypoints"
            case "INVALID_REQUEST":
                return "Invalid route request"
            case "OVER_QUERY_LIMIT":
                return "API quota exceeded. Please try again later."
            case "REQUEST_DENIED":
                return "API key error. Please contact support."
            default:
                return "Directions error: \(status)"
            }
        case .noRoutes:
            return "No routes found"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Helper Extensions

private extension String {
    /// Strip HTML tags from instructions
    func stripHTML() -> String {
        return self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }
}
