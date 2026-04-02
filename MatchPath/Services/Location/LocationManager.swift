import Foundation
import CoreLocation
import Combine

/// Service for managing location tracking and geofencing
/// Handles GPS updates, distance calculations, and arrival notifications
@MainActor
class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()

    // MARK: - Published Properties

    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isTracking = false
    @Published var locationError: LocationError?
    @Published var currentHeading: Double = 0

    // MARK: - Private Properties

    private let locationManager: CLLocationManager
    private var monitoredRegions: Set<String> = []
    private var isTrackingHeading = false

    // MARK: - Initialization

    private override init() {
        self.locationManager = CLLocationManager()
        super.init()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update every 10 meters
        locationManager.activityType = .otherNavigation

        // Check initial authorization status
        if #available(iOS 14.0, macOS 11.0, *) {
            authorizationStatus = locationManager.authorizationStatus
        } else {
            authorizationStatus = CLLocationManager.authorizationStatus()
        }
    }

    // MARK: - Location Tracking

    /// Request location permission from user
    func requestPermission() {
        print("📍 LocationManager: Requesting location permission")
        locationManager.requestWhenInUseAuthorization()
    }

    /// Start tracking user's location
    func startTracking() {
        #if os(iOS)
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            print("❌ LocationManager: Cannot start tracking - not authorized")
            locationError = .notAuthorized
            return
        }
        #else
        guard authorizationStatus == .authorized || authorizationStatus == .authorizedAlways else {
            print("❌ LocationManager: Cannot start tracking - not authorized")
            locationError = .notAuthorized
            return
        }
        #endif

        print("📍 LocationManager: Starting location tracking")
        locationManager.startUpdatingLocation()
        isTracking = true
    }

    /// Stop tracking user's location
    func stopTracking() {
        print("📍 LocationManager: Stopping location tracking")
        locationManager.stopUpdatingLocation()
        isTracking = false
    }

    // MARK: - Heading Tracking

    /// Start tracking device heading (compass direction the phone is facing)
    func startHeadingTracking() {
        #if os(iOS)
        guard CLLocationManager.headingAvailable() else {
            print("📍 LocationManager: Heading not available on this device")
            return
        }
        locationManager.headingFilter = 2 // Update every 2 degrees
        locationManager.startUpdatingHeading()
        isTrackingHeading = true
        print("📍 LocationManager: Started heading tracking")
        #endif
    }

    /// Stop tracking device heading
    func stopHeadingTracking() {
        #if os(iOS)
        locationManager.stopUpdatingHeading()
        isTrackingHeading = false
        print("📍 LocationManager: Stopped heading tracking")
        #endif
    }

    /// Configure for high-frequency updates (used in demo mode)
    func setHighAccuracyMode(_ enabled: Bool) {
        if enabled {
            locationManager.distanceFilter = 1 // Every 1 meter
        } else {
            locationManager.distanceFilter = 10 // Default
        }
        print("📍 LocationManager: High accuracy mode \(enabled ? "enabled" : "disabled")")
    }

    // MARK: - Distance Calculations

    /// Calculate distance from current location to a coordinate
    /// - Parameter coordinate: Target coordinate
    /// - Returns: Distance in meters, or nil if current location unknown
    func distanceTo(coordinate: Coordinate) -> Double? {
        guard let currentLocation = currentLocation else {
            return nil
        }

        let targetLocation = CLLocation(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )

        return currentLocation.distance(from: targetLocation)
    }

    /// Calculate distance from current location to a CLLocationCoordinate2D
    func distanceTo(clCoordinate: CLLocationCoordinate2D) -> Double? {
        guard let currentLocation = currentLocation else {
            return nil
        }

        let targetLocation = CLLocation(
            latitude: clCoordinate.latitude,
            longitude: clCoordinate.longitude
        )

        return currentLocation.distance(from: targetLocation)
    }

    /// Format distance for display
    /// - Parameter meters: Distance in meters
    /// - Returns: Formatted string (e.g., "2.3 mi" or "450 ft")
    func formatDistance(_ meters: Double) -> String {
        let miles = meters / 1609.34

        if miles >= 0.1 {
            return String(format: "%.1f mi", miles)
        } else {
            let feet = meters * 3.28084
            return String(format: "%.0f ft", feet)
        }
    }

    // MARK: - Geofencing

    /// Set up geofence monitoring for a location
    /// - Parameters:
    ///   - coordinate: Location to monitor
    ///   - radius: Radius in meters (default 50m)
    ///   - identifier: Unique identifier for this geofence
    func monitorRegion(coordinate: Coordinate, radius: CLLocationDistance = 50, identifier: String) {
        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else {
            print("❌ LocationManager: Geofencing not available on this device")
            return
        }

        let center = CLLocationCoordinate2D(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )

        let region = CLCircularRegion(
            center: center,
            radius: radius,
            identifier: identifier
        )

        region.notifyOnEntry = true
        region.notifyOnExit = false

        locationManager.startMonitoring(for: region)
        monitoredRegions.insert(identifier)

        print("📍 LocationManager: Started monitoring region: \(identifier)")
    }

    /// Stop monitoring a specific geofence
    func stopMonitoringRegion(identifier: String) {
        guard let region = locationManager.monitoredRegions.first(where: { $0.identifier == identifier }) else {
            return
        }

        locationManager.stopMonitoring(for: region)
        monitoredRegions.remove(identifier)

        print("📍 LocationManager: Stopped monitoring region: \(identifier)")
    }

    /// Stop monitoring all geofences
    func stopMonitoringAllRegions() {
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
        monitoredRegions.removeAll()

        print("📍 LocationManager: Stopped monitoring all regions")
    }

    // MARK: - Helper Methods

    /// Check if user is within a certain distance of a coordinate
    func isNear(coordinate: Coordinate, threshold: Double = 100) -> Bool {
        guard let distance = distanceTo(coordinate: coordinate) else {
            return false
        }
        return distance <= threshold
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        Task { @MainActor in
            self.currentLocation = location
            print("📍 Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            print("❌ Location error: \(error.localizedDescription)")
            self.locationError = .updateFailed(error.localizedDescription)
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            if #available(iOS 14.0, macOS 11.0, *) {
                self.authorizationStatus = manager.authorizationStatus
            } else {
                self.authorizationStatus = CLLocationManager.authorizationStatus()
            }

            print("📍 Authorization status changed: \(self.authorizationStatus.description)")

            // Auto-start tracking if authorized
            #if os(iOS)
            if self.authorizationStatus == .authorizedWhenInUse || self.authorizationStatus == .authorizedAlways {
                self.startTracking()
            }
            #else
            if self.authorizationStatus == .authorized || self.authorizationStatus == .authorizedAlways {
                self.startTracking()
            }
            #endif
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        Task { @MainActor in
            // Use trueHeading if available (requires location), fall back to magneticHeading
            if newHeading.trueHeading >= 0 {
                self.currentHeading = newHeading.trueHeading
            } else {
                self.currentHeading = newHeading.magneticHeading
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        Task { @MainActor in
            print("📍 Entered region: \(region.identifier)")
            NotificationCenter.default.post(
                name: .didEnterGeofence,
                object: nil,
                userInfo: ["identifier": region.identifier]
            )
        }
    }
}

// MARK: - Location Error

enum LocationError: Error {
    case notAuthorized
    case updateFailed(String)
    case unknown

    var description: String {
        switch self {
        case .notAuthorized:
            return "Location access not authorized. Please enable in Settings."
        case .updateFailed(let message):
            return "Location update failed: \(message)"
        case .unknown:
            return "An unknown location error occurred."
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let didEnterGeofence = Notification.Name("didEnterGeofence")
}

// MARK: - Authorization Status Extension

extension CLAuthorizationStatus {
    var description: String {
        switch self {
        case .notDetermined:
            return "Not Determined"
        case .restricted:
            return "Restricted"
        case .denied:
            return "Denied"
        case .authorizedAlways:
            return "Authorized Always"
        case .authorizedWhenInUse:
            return "Authorized When In Use"
        @unknown default:
            return "Unknown"
        }
    }
}
