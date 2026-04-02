import Foundation
import MapKit
import Combine
import SwiftUI

/// ViewModel for managing map state and schedule tracking
@MainActor
class MapViewModel: NSObject, ObservableObject {
    // MARK: - Published Properties

    @Published var region: MKCoordinateRegion
    @Published var annotations: [MKAnnotation] = []
    @Published var currentStepIndex: Int = 0
    @Published var distanceToNextStep: Double?
    @Published var etaToNextStep: TimeInterval?
    @Published var isNavigating = false
    @Published var autoFollowLocation = true // When false, doesn't auto-center on user

    // MARK: - Properties

    let schedule: GameSchedule
    private let locationManager = LocationManager.shared
    private var currentLocationAnnotation: CurrentLocationAnnotation?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    var currentStep: ScheduleStep? {
        guard currentStepIndex < schedule.scheduleSteps.count else { return nil }
        return schedule.scheduleSteps[currentStepIndex]
    }

    var nextStep: ScheduleStep? {
        let nextIndex = currentStepIndex + 1
        guard nextIndex < schedule.scheduleSteps.count else { return nil }
        return schedule.scheduleSteps[nextIndex]
    }

    var progressPercentage: Double {
        guard schedule.scheduleSteps.count > 0 else { return 0 }
        return Double(currentStepIndex) / Double(schedule.scheduleSteps.count)
    }

    var progressText: String {
        return "Step \(currentStepIndex + 1) of \(schedule.scheduleSteps.count)"
    }

    // MARK: - Initialization

    init(schedule: GameSchedule) {
        self.schedule = schedule

        // Initialize region centered on stadium
        let stadiumCoordinate = schedule.game.stadium.coordinate.clLocation
        self.region = MKCoordinateRegion(
            center: stadiumCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )

        super.init()

        setupAnnotations()
        observeLocation()
    }

    // MARK: - Setup

    private func setupAnnotations() {
        var newAnnotations: [MKAnnotation] = []

        // Add stadium
        let stadiumAnnotation = ScheduleAnnotation(
            coordinate: schedule.game.stadium.coordinate.clLocation,
            title: schedule.game.stadium.name,
            subtitle: "Stadium",
            stepType: .arrival,
            isPrimary: true
        )
        newAnnotations.append(stadiumAnnotation)

        // Add parking if exists
        if let parking = schedule.parkingReservation {
            let parkingAnnotation = ScheduleAnnotation(
                coordinate: parking.parkingSpot.coordinate.clLocation,
                title: parking.parkingSpot.name,
                subtitle: "Parking",
                stepType: .parking,
                isPrimary: true
            )
            newAnnotations.append(parkingAnnotation)
        }

        // Add food pickup if exists
        if let foodOrder = schedule.foodOrder {
            // Create coordinate for food vendor (mock for now)
            let vendorCoordinate = CLLocationCoordinate2D(
                latitude: schedule.game.stadium.coordinate.latitude + 0.001,
                longitude: schedule.game.stadium.coordinate.longitude + 0.001
            )

            let foodAnnotation = ScheduleAnnotation(
                coordinate: vendorCoordinate,
                title: "Food Pickup",
                subtitle: foodOrder.vendorLocation,
                stepType: .foodPickup,
                isPrimary: true
            )
            newAnnotations.append(foodAnnotation)
        }

        annotations = newAnnotations
    }

    private func observeLocation() {
        locationManager.$currentLocation
            .sink { [weak self] location in
                guard let self = self, let location = location else { return }
                self.updateCurrentLocationAnnotation(location)
                self.updateDistanceAndETA()
                self.checkStepCompletion()
            }
            .store(in: &cancellables)
    }

    // MARK: - Location Updates

    private func updateCurrentLocationAnnotation(_ location: CLLocation) {
        if let existingAnnotation = currentLocationAnnotation {
            // Update existing annotation
            existingAnnotation.updateCoordinate(location.coordinate)
        } else {
            // Create new annotation
            let annotation = CurrentLocationAnnotation(coordinate: location.coordinate)
            currentLocationAnnotation = annotation
            annotations.append(annotation)
        }

        // Center map on current location if navigating and auto-follow is enabled
        if isNavigating && autoFollowLocation {
            withAnimation {
                region.center = location.coordinate
            }
        }
    }

    private func updateDistanceAndETA() {
        guard nextStep != nil else {
            distanceToNextStep = nil
            etaToNextStep = nil
            return
        }

        // Get distance to next step's location
        // For now, using stadium coordinate as default
        let targetCoordinate = schedule.game.stadium.coordinate

        if let distance = locationManager.distanceTo(coordinate: targetCoordinate) {
            distanceToNextStep = distance

            // Calculate ETA (assume 3 mph walking speed, 30 mph driving)
            let speedMetersPerSecond: Double
            switch schedule.transportationMode {
            case .driving:
                speedMetersPerSecond = 13.41 // ~30 mph
            case .publicTransit:
                speedMetersPerSecond = 8.94 // ~20 mph
            case .rideshare:
                speedMetersPerSecond = 13.41 // ~30 mph
            case .walking:
                speedMetersPerSecond = 1.34 // ~3 mph
            }

            etaToNextStep = distance / speedMetersPerSecond
        }
    }

    private func checkStepCompletion() {
        guard nextStep != nil else { return }

        // Check if user has arrived at next step location
        let targetCoordinate = schedule.game.stadium.coordinate

        if locationManager.isNear(coordinate: targetCoordinate, threshold: 50) {
            // User has arrived at next step
            advanceToNextStep()
        }
    }

    // MARK: - Navigation

    func startNavigation() {
        print("🗺️ Starting navigation")
        locationManager.requestPermission()
        locationManager.startTracking()
        isNavigating = true

        // Set up geofencing for key locations
        setupGeofences()
    }

    func stopNavigation() {
        print("🗺️ Stopping navigation")
        locationManager.stopTracking()
        locationManager.stopMonitoringAllRegions()
        isNavigating = false
    }

    private func setupGeofences() {
        // Monitor stadium
        locationManager.monitorRegion(
            coordinate: schedule.game.stadium.coordinate,
            radius: 100,
            identifier: "stadium"
        )

        // Monitor parking if exists
        if let parking = schedule.parkingReservation {
            locationManager.monitorRegion(
                coordinate: parking.parkingSpot.coordinate,
                radius: 50,
                identifier: "parking"
            )
        }
    }

    func advanceToNextStep() {
        guard currentStepIndex < schedule.scheduleSteps.count - 1 else {
            print("🗺️ Already at final step")
            return
        }

        withAnimation {
            currentStepIndex += 1
        }

        print("🗺️ Advanced to step \(currentStepIndex + 1): \(currentStep?.title ?? "")")
    }

    func goToPreviousStep() {
        guard currentStepIndex > 0 else {
            print("🗺️ Already at first step")
            return
        }

        withAnimation {
            currentStepIndex -= 1
        }

        print("🗺️ Went back to step \(currentStepIndex + 1): \(currentStep?.title ?? "")")
    }

    // MARK: - Map Actions

    func centerOnStadium() {
        withAnimation {
            region.center = schedule.game.stadium.coordinate.clLocation
        }
    }

    func centerOnCurrentLocation() {
        guard let location = locationManager.currentLocation else {
            print("🗺️ No current location available")
            return
        }

        withAnimation {
            region.center = location.coordinate
        }
    }

    func fitAllAnnotations() {
        guard !annotations.isEmpty else { return }

        var minLat = Double.infinity
        var maxLat = -Double.infinity
        var minLon = Double.infinity
        var maxLon = -Double.infinity

        for annotation in annotations {
            minLat = min(minLat, annotation.coordinate.latitude)
            maxLat = max(maxLat, annotation.coordinate.latitude)
            minLon = min(minLon, annotation.coordinate.longitude)
            maxLon = max(maxLon, annotation.coordinate.longitude)
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.5,
            longitudeDelta: (maxLon - minLon) * 1.5
        )

        withAnimation {
            region = MKCoordinateRegion(center: center, span: span)
        }
    }

    // MARK: - Helper Methods

    func formatDistance() -> String? {
        guard let distance = distanceToNextStep else { return nil }
        return locationManager.formatDistance(distance)
    }

    func formatETA() -> String? {
        guard let eta = etaToNextStep else { return nil }

        let minutes = Int(eta / 60)
        if minutes < 1 {
            return "< 1 min"
        } else if minutes == 1 {
            return "1 min"
        } else {
            return "\(minutes) mins"
        }
    }
}
