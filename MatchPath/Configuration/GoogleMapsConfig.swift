import Foundation

/// Configuration for Google Maps Platform APIs
struct GoogleMapsConfig {
    // MARK: - API Key

    /// Your Google Maps API Key
    /// Get one at: https://console.cloud.google.com/google/maps-apis
    /// Required APIs: Geocoding API, Directions API, Distance Matrix API
    static let apiKey: String = {
        // Option 1: From environment variable (check both naming conventions)
        if let key = ProcessInfo.processInfo.environment["GOOGLE_MAPS_API_KEY"] {
            return key
        }
        if let key = ProcessInfo.processInfo.environment["GOOGLE_MAPS_API"] {
            return key
        }

        // Option 2: From Config.xcconfig (recommended for production)
        if let key = Bundle.main.infoDictionary?["GOOGLE_MAPS_API_KEY"] as? String,
           !key.isEmpty && key != "$(GOOGLE_MAPS_API_KEY)" {
            return key
        }

        // No API key configured - mock mode will be used
        return ""
    }()

    // MARK: - API Endpoints

    static let geocodingBaseURL = "https://maps.googleapis.com/maps/api/geocode/json"
    static let directionsBaseURL = "https://maps.googleapis.com/maps/api/directions/json"
    static let distanceMatrixBaseURL = "https://maps.googleapis.com/maps/api/distancematrix/json"
    static let placesBaseURL = "https://maps.googleapis.com/maps/api/place"

    // MARK: - Request Configuration

    /// Maximum number of retries for failed requests
    static let maxRetries = 3

    /// Request timeout in seconds
    static let requestTimeout: TimeInterval = 30

    /// Enable traffic-aware routing
    static let useTrafficData = true

    /// Preferred travel mode for directions
    enum TravelMode: String {
        case driving
        case walking
        case transit
        case bicycling
    }

    static let defaultTravelMode = TravelMode.transit

    // MARK: - Crowd Avoidance Settings

    /// Weight given to crowd levels when scoring routes (0.0 - 1.0)
    /// 0.0 = ignore crowds, prioritize speed
    /// 1.0 = avoid crowds at all costs
    static let crowdAvoidanceWeight: Double = 0.7

    /// Maximum acceptable crowd level (1-5 scale)
    static let maxAcceptableCrowdLevel = 4

    /// Buffer time added for high-crowd scenarios (minutes)
    static let crowdBufferMinutes = 15

    // MARK: - Mock/Demo Mode

    /// Enable mock mode for testing without real API calls
    /// When true, uses realistic mock data instead of Google Maps APIs
    static var useMockMode: Bool = true // Set to false when APIs are enabled
}
