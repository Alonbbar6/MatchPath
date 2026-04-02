import Foundation

/// Configuration manager for API credentials
/// Loads credentials from environment variables or uses defaults from .env file
struct APIConfiguration {
    static let shared = APIConfiguration()
    
    let baseURL: String
    let apiKey: String
    let apiKeyHeader: String
    
    private init() {
        // Try to load from environment variables first, then fall back to hardcoded values
        self.baseURL = ProcessInfo.processInfo.environment["SOCCER_API_URL"] 
            ?? "https://v3.football.api-sports.io"
        
        self.apiKey = ProcessInfo.processInfo.environment["SOCCER_API_KEY"] 
            ?? "e71fd5d5ad177830d297564b06b5df22"
        
        self.apiKeyHeader = ProcessInfo.processInfo.environment["SOCCER_API_KEY_HEADER"] 
            ?? "x-apisports-key"
    }
    
    /// Returns the configured headers for API requests
    var headers: [String: String] {
        return [
            apiKeyHeader: apiKey,
            "Content-Type": "application/json"
        ]
    }
    
    /// Validates that the API configuration is properly set up
    var isValid: Bool {
        return !apiKey.isEmpty && 
               !baseURL.isEmpty && 
               apiKey != "YOUR_API_KEY_HERE"
    }
    
    /// Returns a user-friendly status message about the API configuration
    var statusMessage: String {
        if isValid {
            return "API configured successfully ✓"
        } else {
            return "API key not configured. Please set SOCCER_API_KEY environment variable."
        }
    }
    
    /// Test the API connection
    func testConnection() async throws -> Bool {
        guard let url = URL(string: "\(baseURL)/status") else {
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
