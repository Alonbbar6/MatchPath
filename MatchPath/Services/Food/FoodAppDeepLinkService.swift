import Foundation

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

/// Service for launching external food ordering apps (Grubhub, Uber Eats, DoorDash)
/// This is for deep linking to external apps, separate from the in-app ordering service
class FoodAppDeepLinkService {
    static let shared = FoodAppDeepLinkService()

    private init() {}

    // MARK: - Food Ordering App Types

    enum FoodApp: String, CaseIterable {
        case grubhub = "Grubhub"
        case uberEats = "Uber Eats"
        case doorDash = "DoorDash"

        var icon: String {
            switch self {
            case .grubhub: return "fork.knife.circle.fill"
            case .uberEats: return "bag.fill"
            case .doorDash: return "takeoutbag.and.cup.and.straw.fill"
            }
        }

        var urlScheme: String {
            switch self {
            case .grubhub: return "grubhub://"
            case .uberEats: return "ubereats://"
            case .doorDash: return "doordash://"
            }
        }

        var webFallbackURL: String {
            switch self {
            case .grubhub: return "https://www.grubhub.com"
            case .uberEats: return "https://www.ubereats.com"
            case .doorDash: return "https://www.doordash.com"
            }
        }

        var description: String {
            switch self {
            case .grubhub: return "Official stadium partner"
            case .uberEats: return "Fast delivery & pickup"
            case .doorDash: return "Wide selection of vendors"
            }
        }
    }

    // MARK: - Stadium App Support

    /// Check if stadium has its own food ordering app installed
    func stadiumAppAvailable(for stadium: Stadium) -> Bool {
        guard let scheme = stadium.foodOrderingAppScheme else { return false }
        guard let url = URL(string: "\(scheme)://") else { return false }
        return canOpenURL(url)
    }

    /// Open stadium's official food ordering app
    func openStadiumApp(stadium: Stadium, pickupTime: Date) {
        guard let scheme = stadium.foodOrderingAppScheme else {
            print("❌ No stadium app configured for \(stadium.name)")
            return
        }

        // Try opening the stadium app with food ordering deep link
        let urlString = "\(scheme)://food"
        guard let url = URL(string: urlString) else {
            print("❌ Invalid stadium app URL")
            return
        }

        print("🏟️ FoodAppDeepLinkService: Opening \(stadium.foodOrderingAppName ?? "stadium app") with URL: \(url)")

        openURL(url) { success in
            if success {
                print("✅ Successfully opened stadium app for \(stadium.name)")
            } else {
                print("❌ Failed to open stadium app for \(stadium.name)")
            }
        }
    }

    /// Open stadium's food ordering website in the default browser
    func openStadiumWebsite(stadium: Stadium) {
        guard let urlString = stadium.foodOrderingWebURL else {
            print("❌ No food ordering website configured for \(stadium.name)")
            return
        }

        guard let url = URL(string: urlString) else {
            print("❌ Invalid website URL for \(stadium.name)")
            return
        }

        print("🌐 FoodAppDeepLinkService: Opening \(stadium.name) website: \(url)")

        openURL(url) { success in
            if success {
                print("✅ Successfully opened website for \(stadium.name)")
            } else {
                print("❌ Failed to open website for \(stadium.name)")
            }
        }
    }

    // MARK: - Public Methods

    /// Get list of food ordering apps that are installed on the device
    /// If stadium has its own app, it will be prioritized
    func getAvailableFoodApps(for stadium: Stadium? = nil) -> [FoodApp] {
        var availableApps: [FoodApp] = []

        for app in FoodApp.allCases {
            if canOpenApp(app) {
                availableApps.append(app)
            }
        }

        // If no apps installed, show all with web fallback
        if availableApps.isEmpty {
            return FoodApp.allCases
        }

        return availableApps
    }

    /// Check if a specific food app is installed
    func canOpenApp(_ app: FoodApp) -> Bool {
        guard let url = URL(string: app.urlScheme) else { return false }
        return canOpenURL(url)
    }

    /// Open food ordering app or website
    /// - Parameters:
    ///   - app: The food app to use
    ///   - stadium: The stadium where the game is
    ///   - pickupTime: When user wants to pick up food
    func openFoodApp(
        _ app: FoodApp,
        stadium: Stadium,
        pickupTime: Date
    ) {
        let url: URL?

        // Try app deep link first
        if canOpenApp(app) {
            url = buildDeepLink(
                app: app,
                stadium: stadium,
                pickupTime: pickupTime
            )
        } else {
            // Fall back to web URL
            url = buildWebURL(
                app: app,
                stadium: stadium,
                pickupTime: pickupTime
            )
        }

        guard let orderURL = url else {
            print("❌ FoodAppDeepLinkService: Failed to create URL for \(app.rawValue)")
            return
        }

        print("🍔 FoodAppDeepLinkService: Opening \(app.rawValue) with URL: \(orderURL)")

        openURL(orderURL) { success in
            if success {
                print("✅ FoodAppDeepLinkService: Successfully opened \(app.rawValue)")
            } else {
                print("❌ FoodAppDeepLinkService: Failed to open \(app.rawValue)")
            }
        }
    }

    // MARK: - Deep Link Building

    private func buildDeepLink(
        app: FoodApp,
        stadium: Stadium,
        pickupTime: Date
    ) -> URL? {
        switch app {
        case .grubhub:
            return buildGrubhubDeepLink(stadium: stadium, pickupTime: pickupTime)
        case .uberEats:
            return buildUberEatsDeepLink(stadium: stadium, pickupTime: pickupTime)
        case .doorDash:
            return buildDoorDashDeepLink(stadium: stadium, pickupTime: pickupTime)
        }
    }

    private func buildGrubhubDeepLink(stadium: Stadium, pickupTime: Date) -> URL? {
        var components = URLComponents(string: "grubhub://venue")

        // Grubhub uses venue search or direct venue ID
        components?.queryItems = [
            URLQueryItem(name: "query", value: stadium.name),
            URLQueryItem(name: "latitude", value: "\(stadium.coordinate.latitude)"),
            URLQueryItem(name: "longitude", value: "\(stadium.coordinate.longitude)")
        ]

        return components?.url
    }

    private func buildUberEatsDeepLink(stadium: Stadium, pickupTime: Date) -> URL? {
        var components = URLComponents(string: "ubereats://locations")

        components?.queryItems = [
            URLQueryItem(name: "q", value: stadium.name),
            URLQueryItem(name: "latitude", value: "\(stadium.coordinate.latitude)"),
            URLQueryItem(name: "longitude", value: "\(stadium.coordinate.longitude)")
        ]

        return components?.url
    }

    private func buildDoorDashDeepLink(stadium: Stadium, pickupTime: Date) -> URL? {
        var components = URLComponents(string: "doordash://search")

        components?.queryItems = [
            URLQueryItem(name: "query", value: stadium.name),
            URLQueryItem(name: "pickup_location", value: "\(stadium.coordinate.latitude),\(stadium.coordinate.longitude)")
        ]

        return components?.url
    }

    // MARK: - Web URL Building

    private func buildWebURL(
        app: FoodApp,
        stadium: Stadium,
        pickupTime: Date
    ) -> URL? {
        let baseURL = app.webFallbackURL
        let stadiumQuery = stadium.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        switch app {
        case .grubhub:
            return URL(string: "\(baseURL)/search?searchTerm=\(stadiumQuery)")
        case .uberEats:
            return URL(string: "\(baseURL)/search?q=\(stadiumQuery)")
        case .doorDash:
            return URL(string: "\(baseURL)/search/?q=\(stadiumQuery)")
        }
    }

    // MARK: - Platform helpers

    private func canOpenURL(_ url: URL) -> Bool {
        #if canImport(UIKit)
        return UIApplication.shared.canOpenURL(url)
        #elseif canImport(AppKit)
        // AppKit does not provide a direct canOpenURL equivalent for custom schemes.
        // As a conservative approach, return true for http/https and for known custom schemes we intend to try.
        if let scheme = url.scheme?.lowercased() {
            if scheme == "http" || scheme == "https" {
                return true
            }
            // For custom schemes, we can't reliably check without LaunchServices calls.
            // Return true to attempt open; openURL will report failure in completion.
            return true
        }
        return false
        #else
        return false
        #endif
    }

    private func openURL(_ url: URL, completion: @escaping (Bool) -> Void) {
        #if canImport(UIKit)
        UIApplication.shared.open(url, options: [:]) { success in
            completion(success)
        }
        #elseif canImport(AppKit)
        let success = NSWorkspace.shared.open(url)
        completion(success)
        #else
        completion(false)
        #endif
    }
}
