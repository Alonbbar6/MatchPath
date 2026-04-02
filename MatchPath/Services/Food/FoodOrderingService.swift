import Foundation

/// Service for stadium food ordering and menu management
/// Handles searching for vendors/menus and creating food orders
class FoodOrderingService {
    static let shared = FoodOrderingService()

    private let config = FoodOrderingConfig.shared
    private let session: URLSession

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: configuration)
    }

    // MARK: - Menu Management

    /// Get available food vendors for a stadium
    /// - Parameters:
    ///   - stadiumId: The stadium ID
    ///   - gameDate: The game date
    /// - Returns: Array of available food vendors
    func getStadiumVendors(stadiumId: String, gameDate: Date) async throws -> [FoodVendor] {
        // Use mock mode for testing/demo
        if FoodOrderingConfig.useMockMode {
            print("🎭 Demo Mode: Using mock food vendors")
            // Simulate network delay for realistic testing
            try await Task.sleep(nanoseconds: 600_000_000) // 0.6 second delay
            return FoodVendor.mockVendors(for: stadiumId)
        }

        let endpoint = "\(config.baseURL)/stadiums/\(stadiumId)/vendors"

        guard let url = URL(string: endpoint) else {
            throw FoodOrderingError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"

        // Add headers
        for (key, value) in config.headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        do {
            let (data, response) = try await session.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw FoodOrderingError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                throw FoodOrderingError.serverError(statusCode: httpResponse.statusCode)
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601

            let vendors = try decoder.decode([FoodVendor].self, from: data)
            return vendors

        } catch let error as FoodOrderingError {
            throw error
        } catch {
            // For development: return mock data if API fails
            print("⚠️ Food Ordering API error: \(error.localizedDescription)")
            print("📍 Using mock vendor data for development")
            return FoodVendor.mockVendors(for: stadiumId)
        }
    }

    /// Get specific vendor menu
    /// - Parameter vendorId: The vendor ID
    /// - Returns: The vendor with full menu
    func getVendorMenu(vendorId: String) async throws -> FoodVendor {
        if FoodOrderingConfig.useMockMode {
            print("🎭 Demo Mode: Using mock vendor menu")
            try await Task.sleep(nanoseconds: 400_000_000)

            // Find the vendor in mock data
            if let vendor = FoodVendor.mockVendors(for: "stadium-001").first(where: { $0.id == vendorId }) {
                return vendor
            }

            // Return first vendor as fallback
            return FoodVendor.mockVendors(for: "stadium-001").first!
        }

        // Real API implementation
        let endpoint = "\(config.baseURL)/vendors/\(vendorId)/menu"

        guard let url = URL(string: endpoint) else {
            throw FoodOrderingError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"

        for (key, value) in config.headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw FoodOrderingError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw FoodOrderingError.serverError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode(FoodVendor.self, from: data)
    }

    // MARK: - Order Management

    /// Create a food pre-order
    /// - Parameters:
    ///   - request: The order request with items and pickup time
    ///   - cartItems: The cart items being ordered
    /// - Returns: The created food order
    func createOrder(request: CreateFoodOrderRequest, cartItems: [CartItem]) async throws -> FoodOrder {
        // Use mock mode for testing/demo
        if FoodOrderingConfig.useMockMode {
            print("🎭 Demo Mode: Creating mock food order")
            // Simulate network delay for realistic testing
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay

            // Create a realistic mock order based on the request
            return FoodOrder.mockOrder(from: request, items: cartItems)
        }

        let endpoint = "\(config.baseURL)/orders"

        guard let url = URL(string: endpoint) else {
            throw FoodOrderingError.invalidURL
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
                throw FoodOrderingError.invalidResponse
            }

            guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
                throw FoodOrderingError.serverError(statusCode: httpResponse.statusCode)
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601

            let order = try decoder.decode(FoodOrder.self, from: data)
            return order

        } catch let error as FoodOrderingError {
            throw error
        } catch {
            // For development: return mock order if API fails
            print("⚠️ Food Ordering API error: \(error.localizedDescription)")
            print("📍 Using mock order for development")
            return FoodOrder.mockOrder(from: request, items: cartItems)
        }
    }

    /// Get order status
    /// - Parameter orderId: The order ID
    /// - Returns: The food order with current status
    func getOrderStatus(orderId: String) async throws -> FoodOrder {
        if FoodOrderingConfig.useMockMode {
            print("🎭 Demo Mode: Getting mock order status")
            try await Task.sleep(nanoseconds: 300_000_000)

            // Find order in mock data or return first mock order
            if let order = FoodOrder.mockOrders.first(where: { $0.id == orderId }) {
                return order
            }

            return FoodOrder.mockOrders.first!
        }

        // Real API implementation
        let endpoint = "\(config.baseURL)/orders/\(orderId)"

        guard let url = URL(string: endpoint) else {
            throw FoodOrderingError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"

        for (key, value) in config.headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw FoodOrderingError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw FoodOrderingError.serverError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode(FoodOrder.self, from: data)
    }

    /// Cancel a food order
    /// - Parameter orderId: The ID of the order to cancel
    func cancelOrder(orderId: String) async throws {
        if FoodOrderingConfig.useMockMode {
            print("🎭 Demo Mode: Cancelling order \(orderId)")
            try await Task.sleep(nanoseconds: 400_000_000)
            return
        }

        // Real API implementation
        let endpoint = "\(config.baseURL)/orders/\(orderId)"

        guard let url = URL(string: endpoint) else {
            throw FoodOrderingError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "DELETE"

        for (key, value) in config.headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        let (_, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw FoodOrderingError.invalidResponse
        }

        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 204 else {
            throw FoodOrderingError.serverError(statusCode: httpResponse.statusCode)
        }
    }

    /// Update pickup time for an existing order
    /// - Parameters:
    ///   - orderId: The order ID
    ///   - newTime: The new pickup time
    /// - Returns: The updated food order
    func updatePickupTime(orderId: String, newTime: Date) async throws -> FoodOrder {
        if FoodOrderingConfig.useMockMode {
            print("🎭 Demo Mode: Updating pickup time")
            try await Task.sleep(nanoseconds: 500_000_000)

            // Return mock order with updated time
            let order = FoodOrder.mockOrders.first!
            // Note: In real implementation, would create updated copy
            return order
        }

        // Real API implementation
        let endpoint = "\(config.baseURL)/orders/\(orderId)/pickup-time"

        guard let url = URL(string: endpoint) else {
            throw FoodOrderingError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PATCH"

        for (key, value) in config.headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        let body = ["pickup_time": ISO8601DateFormatter().string(from: newTime)]
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw FoodOrderingError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw FoodOrderingError.serverError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode(FoodOrder.self, from: data)
    }

    // MARK: - Helper Methods

    /// Generate pickup time suggestions based on arrival time
    /// - Parameters:
    ///   - arrivalTime: User's planned arrival time at stadium
    ///   - kickoffTime: Game kickoff time
    /// - Returns: Array of suggested pickup times
    func suggestPickupTimes(arrivalTime: Date, kickoffTime: Date) -> [PickupTimeSuggestion] {
        var suggestions: [PickupTimeSuggestion] = []

        // Option 1: 30 minutes after arrival (Recommended)
        let afterArrival = arrivalTime.addingTimeInterval(30 * 60)
        suggestions.append(PickupTimeSuggestion(
            time: afterArrival,
            label: "After You Arrive",
            description: "30 min after you get there",
            isRecommended: true
        ))

        // Option 2: 1 hour before kickoff
        let beforeKickoff = kickoffTime.addingTimeInterval(-60 * 60)
        if beforeKickoff > arrivalTime {
            suggestions.append(PickupTimeSuggestion(
                time: beforeKickoff,
                label: "Before Kickoff",
                description: "1 hour before the game",
                isRecommended: false
            ))
        }

        // Option 3: 30 minutes before kickoff
        let closeToKickoff = kickoffTime.addingTimeInterval(-30 * 60)
        if closeToKickoff > arrivalTime {
            suggestions.append(PickupTimeSuggestion(
                time: closeToKickoff,
                label: "Just Before Game",
                description: "30 min before kickoff",
                isRecommended: false
            ))
        }

        return suggestions
    }
}

// MARK: - Food Ordering Errors

enum FoodOrderingError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int)
    case vendorUnavailable
    case itemUnavailable
    case invalidPickupTime
    case orderFailed
    case paymentFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let code):
            return "Server error: \(code)"
        case .vendorUnavailable:
            return "This vendor is currently unavailable"
        case .itemUnavailable:
            return "Some items are no longer available"
        case .invalidPickupTime:
            return "Invalid pickup time selected"
        case .orderFailed:
            return "Failed to create order. Please try again."
        case .paymentFailed:
            return "Payment processing failed"
        }
    }
}
