import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Service for launching external parking reservation apps (ParkMobile, SpotHero, ParkWhiz)
class ParkingReservationService {
    static let shared = ParkingReservationService()

    private init() {}

    // MARK: - Parking App Types

    enum ParkingApp: String, CaseIterable {
        case parkMobile = "ParkMobile"
        case spotHero = "SpotHero"
        case parkWhiz = "ParkWhiz"

        var icon: String {
            switch self {
            case .parkMobile: return "parkingsign.circle.fill"
            case .spotHero: return "p.circle.fill"
            case .parkWhiz: return "wand.and.stars"
            }
        }

        var urlScheme: String {
            switch self {
            case .parkMobile: return "parkmobile://"
            case .spotHero: return "spothero://"
            case .parkWhiz: return "parkwhiz://"
            }
        }

        var webFallbackURL: String {
            switch self {
            case .parkMobile: return "https://parkmobile.io"
            case .spotHero: return "https://spothero.com"
            case .parkWhiz: return "https://parkwhiz.com"
            }
        }

        var description: String {
            switch self {
            case .parkMobile: return "Reserve parking spots instantly"
            case .spotHero: return "Find & book parking deals"
            case .parkWhiz: return "Compare parking options"
            }
        }
    }

    // MARK: - Public Methods

    /// Get list of parking apps that are installed on the device
    func getAvailableParkingApps() -> [ParkingApp] {
        #if canImport(UIKit)
        var availableApps: [ParkingApp] = []

        for app in ParkingApp.allCases {
            if canOpenApp(app) {
                availableApps.append(app)
            }
        }

        // If no apps installed, show all with web fallback
        if availableApps.isEmpty {
            return ParkingApp.allCases
        }

        return availableApps
        #else
        // On platforms without UIKit, deep linking to apps isn't supported.
        // Return all to enable web fallbacks.
        return ParkingApp.allCases
        #endif
    }

    /// Check if a specific parking app is installed
    func canOpenApp(_ app: ParkingApp) -> Bool {
        #if canImport(UIKit)
        guard let url = URL(string: app.urlScheme) else { return false }
        return UIApplication.shared.canOpenURL(url)
        #else
        return false
        #endif
    }

    /// Open parking reservation app or website
    /// - Parameters:
    ///   - app: The parking app to use
    ///   - parkingSpot: The parking spot to reserve
    ///   - startTime: Reservation start time
    ///   - endTime: Reservation end time
    func openParkingApp(
        _ app: ParkingApp,
        for parkingSpot: ParkingSpot? = nil,
        at location: Coordinate? = nil,
        locationName: String? = nil,
        startTime: Date,
        endTime: Date
    ) {
        let url: URL?

        // Try app deep link first
        if canOpenApp(app) {
            url = buildDeepLink(
                app: app,
                parkingSpot: parkingSpot,
                location: location,
                locationName: locationName,
                startTime: startTime,
                endTime: endTime
            )
        } else {
            // Fall back to web URL
            url = buildWebURL(
                app: app,
                parkingSpot: parkingSpot,
                location: location,
                locationName: locationName,
                startTime: startTime,
                endTime: endTime
            )
        }

        guard let reservationURL = url else {
            print("❌ ParkingReservationService: Failed to create URL for \(app.rawValue)")
            return
        }

        print("🅿️ ParkingReservationService: Opening \(app.rawValue) with URL: \(reservationURL)")

        #if canImport(UIKit)
        UIApplication.shared.open(reservationURL) { success in
            if success {
                print("✅ ParkingReservationService: Successfully opened \(app.rawValue)")
            } else {
                print("❌ ParkingReservationService: Failed to open \(app.rawValue)")
            }
        }
        #else
        // On non-UIKit platforms, just print the URL (caller can handle opening if desired)
        // Optionally, you could use NSWorkspace on macOS; but keeping this service iOS-centric.
        #endif
    }

    // MARK: - Deep Link Building

    private func buildDeepLink(
        app: ParkingApp,
        parkingSpot: ParkingSpot?,
        location: Coordinate?,
        locationName: String?,
        startTime: Date,
        endTime: Date
    ) -> URL? {
        switch app {
        case .parkMobile:
            return buildParkMobileDeepLink(
                parkingSpot: parkingSpot,
                location: location,
                locationName: locationName,
                startTime: startTime,
                endTime: endTime
            )
        case .spotHero:
            return buildSpotHeroDeepLink(
                parkingSpot: parkingSpot,
                location: location,
                locationName: locationName,
                startTime: startTime,
                endTime: endTime
            )
        case .parkWhiz:
            return buildParkWhizDeepLink(
                parkingSpot: parkingSpot,
                location: location,
                locationName: locationName,
                startTime: startTime,
                endTime: endTime
            )
        }
    }

    private func buildParkMobileDeepLink(
        parkingSpot: ParkingSpot?,
        location: Coordinate?,
        locationName: String?,
        startTime: Date,
        endTime: Date
    ) -> URL? {
        var components = URLComponents(string: "parkmobile://reserve")

        let coord = parkingSpot?.coordinate ?? location ?? Coordinate(latitude: 0, longitude: 0)

        components?.queryItems = [
            URLQueryItem(name: "latitude", value: "\(coord.latitude)"),
            URLQueryItem(name: "longitude", value: "\(coord.longitude)"),
            URLQueryItem(name: "start", value: ISO8601DateFormatter().string(from: startTime)),
            URLQueryItem(name: "end", value: ISO8601DateFormatter().string(from: endTime))
        ]

        if let name = parkingSpot?.name ?? locationName {
            components?.queryItems?.append(URLQueryItem(name: "location", value: name))
        }

        return components?.url
    }

    private func buildSpotHeroDeepLink(
        parkingSpot: ParkingSpot?,
        location: Coordinate?,
        locationName: String?,
        startTime: Date,
        endTime: Date
    ) -> URL? {
        var components = URLComponents(string: "spothero://search")

        let destination = parkingSpot?.name ?? locationName ?? "Stadium"

        components?.queryItems = [
            URLQueryItem(name: "destination", value: destination),
            URLQueryItem(name: "starts", value: ISO8601DateFormatter().string(from: startTime)),
            URLQueryItem(name: "ends", value: ISO8601DateFormatter().string(from: endTime))
        ]

        return components?.url
    }

    private func buildParkWhizDeepLink(
        parkingSpot: ParkingSpot?,
        location: Coordinate?,
        locationName: String?,
        startTime: Date,
        endTime: Date
    ) -> URL? {
        var components = URLComponents(string: "parkwhiz://search")

        let destination = parkingSpot?.address ?? locationName ?? "Stadium"

        components?.queryItems = [
            URLQueryItem(name: "q", value: destination),
            URLQueryItem(name: "start", value: ISO8601DateFormatter().string(from: startTime)),
            URLQueryItem(name: "end", value: ISO8601DateFormatter().string(from: endTime))
        ]

        return components?.url
    }

    // MARK: - Web URL Building

    private func buildWebURL(
        app: ParkingApp,
        parkingSpot: ParkingSpot?,
        location: Coordinate?,
        locationName: String?,
        startTime: Date,
        endTime: Date
    ) -> URL? {
        let baseURL = app.webFallbackURL

        switch app {
        case .parkMobile:
            return URL(string: "\(baseURL)/find-parking")
        case .spotHero:
            let destination = (parkingSpot?.name ?? locationName ?? "Stadium").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            return URL(string: "\(baseURL)/search?q=\(destination)")
        case .parkWhiz:
            let destination = (parkingSpot?.address ?? locationName ?? "Stadium").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            return URL(string: "\(baseURL)/search/?q=\(destination)")
        }
    }
}
