import Foundation
import CoreLocation

/// Service for interacting with the ParkMobile API
/// Handles searching for parking spots and creating reservations
class ParkMobileService {
    static let shared = ParkMobileService()

    private let config = ParkMobileConfig.shared
    private let session: URLSession

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: configuration)
    }

    // MARK: - Search Parking

    /// Search for available parking spots near a location
    /// - Parameters:
    ///   - request: The search request with location and time parameters
    /// - Returns: Array of available parking spots
    func searchParkingSpots(request: ParkingSearchRequest) async throws -> [ParkingSpot] {
        // Use mock mode for testing/demo
        if ParkMobileConfig.useMockMode {
            print("🎭 Demo Mode: Using mock parking data")
            // Simulate network delay for realistic testing
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
            return ParkingSpot.mockSpots
        }

        let endpoint = "\(config.baseURL)/parking/search"

        guard let url = URL(string: endpoint) else {
            throw ParkingError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"

        // Add headers
        for (key, value) in config.headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        // Add body
        let requestBody = try JSONSerialization.data(withJSONObject: request.parameters)
        urlRequest.httpBody = requestBody

        do {
            let (data, response) = try await session.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw ParkingError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                throw ParkingError.serverError(statusCode: httpResponse.statusCode)
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601

            let parkingResponse = try decoder.decode(ParkingSearchResponse.self, from: data)
            return parkingResponse.spots

        } catch let error as ParkingError {
            throw error
        } catch {
            // For development: return mock data if API fails
            print("⚠️ ParkMobile API error: \(error.localizedDescription)")
            print("📍 Using mock parking data for development")
            return ParkingSpot.mockSpots
        }
    }

    /// Search for parking near a stadium
    /// - Parameters:
    ///   - stadium: The stadium to search near
    ///   - startTime: When parking is needed
    ///   - endTime: When parking ends
    ///   - radius: Search radius in meters (default: 2000m)
    /// - Returns: Array of available parking spots
    func searchParkingNearStadium(
        stadium: Stadium,
        startTime: Date,
        endTime: Date,
        radius: Double = 2000
    ) async throws -> [ParkingSpot] {
        let request = ParkingSearchRequest(
            latitude: stadium.coordinate.latitude,
            longitude: stadium.coordinate.longitude,
            radius: radius,
            startTime: startTime,
            endTime: endTime,
            features: nil
        )

        return try await searchParkingSpots(request: request)
    }

    // MARK: - Create Reservation

    /// Create a parking reservation
    /// - Parameters:
    ///   - request: The booking request with spot and time details
    /// - Returns: The created parking reservation
    func createReservation(request: ParkingBookingRequest) async throws -> ParkingReservation {
        // Use mock mode for testing/demo
        if ParkMobileConfig.useMockMode {
            print("🎭 Demo Mode: Creating mock parking reservation")
            // Simulate network delay for realistic testing
            try await Task.sleep(nanoseconds: 800_000_000) // 0.8 second delay

            // Create a realistic mock reservation based on the request
            let mockReservation = ParkingReservation(
                id: "mock-res-\(UUID().uuidString.prefix(8))",
                parkingSpot: ParkingSpot.mockSpots.first(where: { $0.id == request.spotId }) ?? ParkingSpot.mockSpots[0],
                startTime: request.startTime,
                endTime: request.endTime,
                confirmationCode: "PM-DEMO-\(Int.random(in: 1000...9999))",
                qrCode: nil,
                status: .confirmed,
                createdAt: Date()
            )

            return mockReservation
        }

        let endpoint = "\(config.baseURL)/parking/reserve"

        guard let url = URL(string: endpoint) else {
            throw ParkingError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"

        // Add headers
        for (key, value) in config.headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        // Add body
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        let requestBody = try encoder.encode(request)
        urlRequest.httpBody = requestBody

        do {
            let (data, response) = try await session.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw ParkingError.invalidResponse
            }

            guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
                throw ParkingError.serverError(statusCode: httpResponse.statusCode)
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601

            let reservation = try decoder.decode(ParkingReservation.self, from: data)
            return reservation

        } catch let error as ParkingError {
            throw error
        } catch {
            // For development: return mock reservation if API fails
            print("⚠️ ParkMobile API error: \(error.localizedDescription)")
            print("📍 Using mock reservation for development")
            return ParkingReservation.mockReservation
        }
    }

    // MARK: - Cancel Reservation

    /// Cancel an existing parking reservation
    /// - Parameter reservationId: The ID of the reservation to cancel
    func cancelReservation(reservationId: String) async throws {
        let endpoint = "\(config.baseURL)/parking/reserve/\(reservationId)"

        guard let url = URL(string: endpoint) else {
            throw ParkingError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "DELETE"

        // Add headers
        for (key, value) in config.headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        let (_, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ParkingError.invalidResponse
        }

        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 204 else {
            throw ParkingError.serverError(statusCode: httpResponse.statusCode)
        }
    }

    // MARK: - Get Reservation Details

    /// Get details of an existing reservation
    /// - Parameter reservationId: The ID of the reservation
    /// - Returns: The parking reservation
    func getReservation(reservationId: String) async throws -> ParkingReservation {
        let endpoint = "\(config.baseURL)/parking/reserve/\(reservationId)"

        guard let url = URL(string: endpoint) else {
            throw ParkingError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"

        // Add headers
        for (key, value) in config.headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ParkingError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw ParkingError.serverError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode(ParkingReservation.self, from: data)
    }
}

// MARK: - Response Models

private struct ParkingSearchResponse: Codable {
    let spots: [ParkingSpot]
    let total: Int
}

// MARK: - Parking Errors

enum ParkingError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int)
    case noSpotsAvailable
    case reservationFailed
    case invalidSpotId

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let code):
            return "Server error: \(code)"
        case .noSpotsAvailable:
            return "No parking spots available"
        case .reservationFailed:
            return "Failed to create reservation"
        case .invalidSpotId:
            return "Invalid parking spot ID"
        }
    }
}
