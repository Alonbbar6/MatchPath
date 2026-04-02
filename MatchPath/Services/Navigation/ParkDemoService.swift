import Foundation
import CoreLocation
import Combine

/// Service that maps a real park's GPS area to a stadium's local coordinate system.
/// When active, walking in a park drives the indoor compass as if walking inside the stadium.
@MainActor
class ParkDemoService: ObservableObject {
    static let shared = ParkDemoService()

    // MARK: - Published State

    @Published var isEnabled: Bool = false
    @Published var parkCenter: CLLocationCoordinate2D?
    @Published var selectedStadiumId: String = "hard-rock-stadium"
    @Published var scaleFactor: Double = 10.0

    private init() {}

    // MARK: - Activation

    /// Activate demo mode with the given park center and stadium.
    /// - Parameters:
    ///   - parkCenter: GPS coordinate at the center of the park (maps to stadium center)
    ///   - stadiumId: Which stadium to simulate
    ///   - scale: Scale factor (1.0 = 1m walked = 1m in stadium)
    func activate(parkCenter: CLLocationCoordinate2D, stadiumId: String, scale: Double = 1.0) {
        self.parkCenter = parkCenter
        self.selectedStadiumId = stadiumId
        self.scaleFactor = scale
        self.isEnabled = true
        print("ParkDemoService: Activated for \(stadiumId), scale=\(scale)")
    }

    /// Deactivate demo mode
    func deactivate() {
        isEnabled = false
        print("ParkDemoService: Deactivated")
    }

    // MARK: - GPS to Stadium Coordinate Transform

    /// Convert a real GPS coordinate to stadium coordinates (x, y).
    ///
    /// Algorithm:
    /// 1. Compute GPS offset from park center in meters (Mercator approximation)
    /// 2. Apply rotation to align with stadium coordinate system
    /// 3. Apply scale factor
    /// 4. Return as (x, y) coordinates
    func gpsToStadiumCoordinates(gpsLat: Double, gpsLon: Double, stadiumData: StadiumNavigationData) -> (x: Double, y: Double) {
        // Use parkCenter as origin when in demo mode (user's park location maps to stadium center)
        // Falls back to stadium reference point if parkCenter not set
        let centerLat = parkCenter?.latitude ?? stadiumData.referencePoint.latitude
        let centerLon = parkCenter?.longitude ?? stadiumData.referencePoint.longitude

        // Step 1: GPS offset in meters from park center
        // At small scales (<1km), Mercator approximation is sub-meter accurate
        let latRadians = centerLat * .pi / 180.0
        let dx = (gpsLon - centerLon) * cos(latRadians) * 111_320.0
        let dy = (gpsLat - centerLat) * 111_320.0

        // Step 2: Apply stadium rotation (rotation is degrees CW from north)
        let rotRad = -stadiumData.localCoordinateSystem.rotation * .pi / 180.0
        let rotatedX = dx * cos(rotRad) - dy * sin(rotRad)
        let rotatedY = dx * sin(rotRad) + dy * cos(rotRad)

        // Step 3: Apply scale factor
        let scaledX = rotatedX * scaleFactor
        let scaledY = rotatedY * scaleFactor

        return (x: scaledX, y: scaledY)
    }
}
