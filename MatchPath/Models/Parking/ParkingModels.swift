import Foundation
import CoreLocation

// MARK: - Transportation Mode

enum TransportationMode: String, Codable, CaseIterable {
    case driving = "Driving"
    case publicTransit = "Public Transit"
    case rideshare = "Rideshare"
    case walking = "Walking"

    var icon: String {
        switch self {
        case .driving: return "car.fill"
        case .publicTransit: return "bus.fill"
        case .rideshare: return "figure.wave"
        case .walking: return "figure.walk"
        }
    }

    var description: String {
        switch self {
        case .driving: return "Drive and park near the stadium"
        case .publicTransit: return "Use buses, trains, or metro"
        case .rideshare: return "Use Uber, Lyft, or taxi"
        case .walking: return "Walk to the stadium"
        }
    }

    var requiresParking: Bool {
        return self == .driving
    }
}

// MARK: - Parking Spot

struct ParkingSpot: Identifiable, Codable {
    let id: String
    let name: String
    let address: String
    let coordinate: Coordinate
    let distanceToStadium: Double // in meters
    let walkingTimeToStadium: Int // in minutes
    let pricePerHour: Double
    let totalPrice: Double // for the expected duration
    let availableSpots: Int
    let features: [ParkingFeature]
    let provider: String // e.g., "ParkMobile", "SpotHero"
    let imageURL: String?
    let operatingHours: OperatingHours

    var distanceDisplay: String {
        let miles = distanceToStadium * 0.000621371
        return String(format: "%.1f mi", miles)
    }

    var priceDisplay: String {
        return String(format: "$%.2f", totalPrice)
    }

    var availabilityStatus: ParkingAvailability {
        if availableSpots == 0 {
            return .full
        } else if availableSpots <= 5 {
            return .limited
        } else {
            return .available
        }
    }
}

enum ParkingAvailability: String, Codable {
    case available = "Available"
    case limited = "Limited"
    case full = "Full"

    var color: String {
        switch self {
        case .available: return "green"
        case .limited: return "orange"
        case .full: return "red"
        }
    }
}

enum ParkingFeature: String, Codable, CaseIterable {
    case covered = "Covered"
    case security = "24/7 Security"
    case evCharging = "EV Charging"
    case handicapAccessible = "Handicap Accessible"
    case oversized = "Oversized Vehicles"
    case attendant = "Attendant On-Site"

    var icon: String {
        switch self {
        case .covered: return "roof.fill"
        case .security: return "shield.fill"
        case .evCharging: return "bolt.fill"
        case .handicapAccessible: return "accessibility.fill"
        case .oversized: return "truck.box.fill"
        case .attendant: return "person.fill"
        }
    }
}

struct OperatingHours: Codable {
    let open24Hours: Bool
    let openingTime: String? // "06:00 AM"
    let closingTime: String? // "11:00 PM"

    var displayText: String {
        if open24Hours {
            return "Open 24 Hours"
        } else if let open = openingTime, let close = closingTime {
            return "\(open) - \(close)"
        } else {
            return "Hours Vary"
        }
    }
}

// MARK: - Parking Reservation

struct ParkingReservation: Identifiable, Codable {
    let id: String
    let parkingSpot: ParkingSpot
    let startTime: Date
    let endTime: Date
    let confirmationCode: String
    let qrCode: String? // Base64 encoded QR code for entry
    let status: ReservationStatus
    let createdAt: Date

    var duration: TimeInterval {
        return endTime.timeIntervalSince(startTime)
    }

    var durationDisplay: String {
        let hours = Int(duration / 3600)
        return "\(hours) hours"
    }

    var isActive: Bool {
        let now = Date()
        return now >= startTime && now <= endTime && status == .confirmed
    }
}

enum ReservationStatus: String, Codable {
    case pending = "Pending"
    case confirmed = "Confirmed"
    case cancelled = "Cancelled"
    case expired = "Expired"

    var color: String {
        switch self {
        case .pending: return "yellow"
        case .confirmed: return "green"
        case .cancelled: return "red"
        case .expired: return "gray"
        }
    }
}

// MARK: - Parking Search Request

struct ParkingSearchRequest: Codable {
    let latitude: Double
    let longitude: Double
    let radius: Double // in meters
    let startTime: Date
    let endTime: Date
    let features: [ParkingFeature]?

    var parameters: [String: Any] {
        var params: [String: Any] = [
            "latitude": latitude,
            "longitude": longitude,
            "radius": radius,
            "start_time": ISO8601DateFormatter().string(from: startTime),
            "end_time": ISO8601DateFormatter().string(from: endTime)
        ]

        if let features = features, !features.isEmpty {
            params["features"] = features.map { $0.rawValue }
        }

        return params
    }
}

// MARK: - Parking Booking Request

struct ParkingBookingRequest: Codable {
    let spotId: String
    let startTime: Date
    let endTime: Date
    let vehicleInfo: VehicleInfo?
    let paymentMethodId: String
}

struct VehicleInfo: Codable {
    let make: String
    let model: String
    let color: String
    let licensePlate: String
}

// MARK: - Mock Data for Development

extension ParkingSpot {
    static let mockSpots: [ParkingSpot] = [
        ParkingSpot(
            id: "park-001",
            name: "Stadium Plaza Parking",
            address: "350 Don Shula Dr, Miami Gardens, FL 33056",
            coordinate: Coordinate(latitude: 25.9585, longitude: -80.2395),
            distanceToStadium: 200,
            walkingTimeToStadium: 3,
            pricePerHour: 15.00,
            totalPrice: 45.00,
            availableSpots: 42,
            features: [.covered, .security, .handicapAccessible],
            provider: "ParkMobile",
            imageURL: nil,
            operatingHours: OperatingHours(open24Hours: true, openingTime: nil, closingTime: nil)
        ),
        ParkingSpot(
            id: "park-002",
            name: "North Lot",
            address: "2269 NW 199th St, Miami Gardens, FL 33056",
            coordinate: Coordinate(latitude: 25.9600, longitude: -80.2400),
            distanceToStadium: 400,
            walkingTimeToStadium: 6,
            pricePerHour: 10.00,
            totalPrice: 30.00,
            availableSpots: 128,
            features: [.security, .oversized],
            provider: "ParkMobile",
            imageURL: nil,
            operatingHours: OperatingHours(open24Hours: false, openingTime: "6:00 AM", closingTime: "11:00 PM")
        ),
        ParkingSpot(
            id: "park-003",
            name: "Premium Covered Garage",
            address: "345 Don Shula Dr, Miami Gardens, FL 33056",
            coordinate: Coordinate(latitude: 25.9575, longitude: -80.2385),
            distanceToStadium: 150,
            walkingTimeToStadium: 2,
            pricePerHour: 25.00,
            totalPrice: 75.00,
            availableSpots: 8,
            features: [.covered, .security, .evCharging, .attendant, .handicapAccessible],
            provider: "ParkMobile",
            imageURL: nil,
            operatingHours: OperatingHours(open24Hours: true, openingTime: nil, closingTime: nil)
        ),
        ParkingSpot(
            id: "park-004",
            name: "Budget Parking",
            address: "2301 NW 199th St, Miami Gardens, FL 33056",
            coordinate: Coordinate(latitude: 25.9610, longitude: -80.2410),
            distanceToStadium: 800,
            walkingTimeToStadium: 12,
            pricePerHour: 5.00,
            totalPrice: 15.00,
            availableSpots: 250,
            features: [.oversized],
            provider: "ParkMobile",
            imageURL: nil,
            operatingHours: OperatingHours(open24Hours: false, openingTime: "5:00 AM", closingTime: "12:00 AM")
        )
    ]
}

extension ParkingReservation {
    static let mockReservation = ParkingReservation(
        id: "res-001",
        parkingSpot: ParkingSpot.mockSpots[0],
        startTime: Date().addingTimeInterval(-3600), // 1 hour ago
        endTime: Date().addingTimeInterval(7200), // 2 hours from now
        confirmationCode: "PM-ABC123",
        qrCode: nil,
        status: .confirmed,
        createdAt: Date().addingTimeInterval(-7200)
    )
}
