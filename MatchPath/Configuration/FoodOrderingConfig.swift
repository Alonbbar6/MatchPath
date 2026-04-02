import Foundation

/// Configuration manager for stadium food ordering API
/// Loads credentials from environment variables or uses defaults from .env file
struct FoodOrderingConfig {
    static let shared = FoodOrderingConfig()

    let apiKey: String
    let baseURL: String

    /// Set to true to use mock data instead of real API calls (for testing/demo)
    static let useMockMode = true

    private init() {
        // Try to load from environment variables first, then fall back to hardcoded values
        self.apiKey = ProcessInfo.processInfo.environment["FOOD_ORDERING_API_KEY"]
            ?? "demo_food_api_key"

        // Could be Appetize, Grubhub, or custom backend
        self.baseURL = "https://api.stadium-food.com/v1"
    }

    /// Returns the configured headers for API requests
    var headers: [String: String] {
        return [
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
    }

    /// Validates that the API configuration is properly set up
    var isValid: Bool {
        return !apiKey.isEmpty && apiKey != "YOUR_FOOD_API_KEY_HERE"
    }

    /// Returns a user-friendly status message about the API configuration
    var statusMessage: String {
        if isValid {
            return "Food Ordering API configured successfully ✓"
        } else {
            return "Food Ordering API key not configured. Please set FOOD_ORDERING_API_KEY environment variable."
        }
    }

    /// Test the API connection
    func testConnection() async throws -> Bool {
        guard let url = URL(string: "\(baseURL)/health") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            return false
        }

        return httpResponse.statusCode == 200
    }
}
