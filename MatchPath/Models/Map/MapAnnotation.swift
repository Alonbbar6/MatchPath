import Foundation
import MapKit

/// Custom annotation for schedule locations on the map
class ScheduleAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?
    let stepType: StepType
    let isPrimary: Bool // Stadium, parking, food are primary

    init(
        coordinate: CLLocationCoordinate2D,
        title: String?,
        subtitle: String?,
        stepType: StepType,
        isPrimary: Bool = false
    ) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.stepType = stepType
        self.isPrimary = isPrimary
        super.init()
    }

    /// Get SF Symbol icon name for this annotation type
    var iconName: String {
        switch stepType {
        case .departure:
            return "house.fill"
        case .parking:
            return "parkingsign.circle.fill"
        case .transit:
            return "tram.fill"
        case .arrival:
            return "sportscourt.fill"
        case .foodPickup:
            return "fork.knife.circle.fill"
        case .entry:
            return "door.left.hand.open"
        case .seating:
            return "chair.fill"
        case .milestone:
            return "soccerball.circle.fill"
        }
    }

    /// Get color for this annotation type
    #if os(iOS)
    var color: UIColor {
        switch stepType {
        case .departure:
            return .systemBlue
        case .parking:
            return .systemIndigo
        case .transit:
            return .systemGreen
        case .arrival:
            return .systemRed
        case .foodPickup:
            return .systemOrange
        case .entry:
            return .systemPurple
        case .seating:
            return .systemPink
        case .milestone:
            return .systemRed
        }
    }
    #else
    var color: NSColor {
        switch stepType {
        case .departure:
            return .systemBlue
        case .parking:
            return .systemIndigo
        case .transit:
            return .systemGreen
        case .arrival:
            return .systemRed
        case .foodPickup:
            return .systemOrange
        case .entry:
            return .systemPurple
        case .seating:
            return .systemPink
        case .milestone:
            return .systemRed
        }
    }
    #endif
}

/// Annotation for user's current location
class CurrentLocationAnnotation: NSObject, MKAnnotation {
    @objc dynamic var coordinate: CLLocationCoordinate2D
    let title: String? = "You"
    let subtitle: String? = "Current Location"

    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        super.init()
    }

    func updateCoordinate(_ newCoordinate: CLLocationCoordinate2D) {
        willChangeValue(for: \.coordinate)
        coordinate = newCoordinate
        didChangeValue(for: \.coordinate)
    }
}

/// Helper to convert Coordinate model to CLLocationCoordinate2D
extension Coordinate {
    var clCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

/// Helper to create ScheduleAnnotation from ScheduleStep
extension ScheduleStep {
    func toAnnotation(coordinate: CLLocationCoordinate2D) -> ScheduleAnnotation {
        ScheduleAnnotation(
            coordinate: coordinate,
            title: title,
            subtitle: description,
            stepType: stepType,
            isPrimary: stepType == .parking || stepType == .foodPickup || stepType == .arrival
        )
    }
}
