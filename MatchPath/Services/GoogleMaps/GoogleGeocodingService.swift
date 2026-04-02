import Foundation
import CoreLocation

/// Service for converting addresses to coordinates using Google Geocoding API
class GoogleGeocodingService {
    static let shared = GoogleGeocodingService()

    private init() {}

    // MARK: - Public Methods

    /// Convert an address string to geographic coordinates
    /// - Parameter address: The address to geocode (e.g., "1600 Amphitheatre Parkway, Mountain View, CA")
    /// - Returns: Coordinates (latitude, longitude)
    /// - Throws: GeocodingError if geocoding fails
    func geocodeAddress(_ address: String) async throws -> CLLocationCoordinate2D {
        guard !address.isEmpty else {
            throw GeocodingError.invalidAddress
        }

        let result = try await performGeocodingRequest(address: address)
        return result.coordinate
    }

    /// Get detailed location info including formatted address
    /// - Parameter address: The address to geocode
    /// - Returns: Complete location information
    func geocodeAddressDetailed(_ address: String) async throws -> GeocodingResult {
        guard !address.isEmpty else {
            throw GeocodingError.invalidAddress
        }

        return try await performGeocodingRequest(address: address)
    }

    // MARK: - Private Methods

    private func performGeocodingRequest(address: String) async throws -> GeocodingResult {
        // Build URL with query parameters
        var components = URLComponents(string: GoogleMapsConfig.geocodingBaseURL)!
        components.queryItems = [
            URLQueryItem(name: "address", value: address),
            URLQueryItem(name: "key", value: GoogleMapsConfig.apiKey)
        ]

        guard let url = components.url else {
            throw GeocodingError.invalidURL
        }

        // Make API request
        let (data, response) = try await URLSession.shared.data(from: url)

        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeocodingError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw GeocodingError.httpError(statusCode: httpResponse.statusCode)
        }

        // Parse JSON response
        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(GeocodingAPIResponse.self, from: data)

        // Check API status
        guard apiResponse.status == "OK" else {
            throw GeocodingError.apiError(status: apiResponse.status)
        }

        // Extract first result
        guard let firstResult = apiResponse.results.first else {
            throw GeocodingError.noResults
        }

        return GeocodingResult(
            coordinate: CLLocationCoordinate2D(
                latitude: firstResult.geometry.location.lat,
                longitude: firstResult.geometry.location.lng
            ),
            formattedAddress: firstResult.formatted_address,
            placeId: firstResult.place_id
        )
    }
}

// MARK: - Models

struct GeocodingResult {
    let coordinate: CLLocationCoordinate2D
    let formattedAddress: String
    let placeId: String
}

// MARK: - API Response Models

private struct GeocodingAPIResponse: Codable {
    let results: [GeocodingAPIResult]
    let status: String
}

private struct GeocodingAPIResult: Codable {
    let formatted_address: String
    let geometry: Geometry
    let place_id: String

    struct Geometry: Codable {
        let location: Location

        struct Location: Codable {
            let lat: Double
            let lng: Double
        }
    }
}

// MARK: - Errors

enum GeocodingError: LocalizedError {
    case invalidAddress
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case apiError(status: String)
    case noResults
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidAddress:
            return "Please enter a valid address"
        case .invalidURL:
            return "Invalid request URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "Server error: \(code)"
        case .apiError(let status):
            switch status {
            case "ZERO_RESULTS":
                return "Address not found. Please check and try again."
            case "OVER_QUERY_LIMIT":
                return "API quota exceeded. Please try again later."
            case "REQUEST_DENIED":
                return "API key error. Please contact support."
            case "INVALID_REQUEST":
                return "Invalid request. Please check your address."
            default:
                return "Geocoding failed: \(status)"
            }
        case .noResults:
            return "No location found for this address"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
