import Foundation
import CoreLocation

// MARK: - Stadium Navigation Data Models
// These models parse the JSON data from the stadium navigation files

struct StadiumNavigationData: Codable {
    let stadiumId: String
    let stadiumName: String
    let officialName: String
    let location: StadiumLocation
    let capacity: Int
    let referencePoint: ReferencePoint
    let localCoordinateSystem: LocalCoordinateSystem
    let levels: [StadiumLevel]
    let gates: [StadiumGate]
    let sections: [StadiumSection]
    let amenities: [StadiumAmenity]
    let metadata: StadiumMetadata

    enum CodingKeys: String, CodingKey {
        case stadiumId = "stadium_id"
        case stadiumName = "stadium_name"
        case officialName = "official_name"
        case location, capacity
        case referencePoint = "reference_point"
        case localCoordinateSystem = "local_coordinate_system"
        case levels, gates, sections, amenities, metadata
    }
}

struct StadiumLocation: Codable {
    let address: String
    let city: String
    let stateProvince: String
    let country: String
    let postalCode: String

    enum CodingKeys: String, CodingKey {
        case address, city
        case stateProvince = "state_province"
        case country
        case postalCode = "postal_code"
    }
}

struct ReferencePoint: Codable {
    let latitude: Double
    let longitude: Double
    let altitude: Double
    let description: String?
    let coordinateSystem: String?

    enum CodingKeys: String, CodingKey {
        case latitude, longitude, altitude, description
        case coordinateSystem = "coordinate_system"
    }

    var clLocation: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct LocalCoordinateSystem: Codable {
    let origin: ReferencePoint
    let units: String
    let rotation: Double
    let description: String
}

struct StadiumLevel: Codable {
    let levelId: String
    let levelName: String
    let floor: Int
    let elevationMeters: Double
    let description: String

    enum CodingKeys: String, CodingKey {
        case levelId = "level_id"
        case levelName = "level_name"
        case floor
        case elevationMeters = "elevation_meters"
        case description
    }
}

struct StadiumGate: Codable {
    let id: String
    let name: String
    let type: String
    let latitude: Double
    let longitude: Double
    let floor: Int
    let levelId: String
    let localX: Double
    let localY: Double
    let localZ: Double
    let servesSections: [String]
    let accessible: Bool
    let description: String

    enum CodingKeys: String, CodingKey {
        case id, name, type, latitude, longitude, floor
        case levelId = "level_id"
        case localX = "local_x"
        case localY = "local_y"
        case localZ = "local_z"
        case servesSections = "serves_sections"
        case accessible, description
    }

    var coordinate: Coordinate {
        Coordinate(latitude: latitude, longitude: longitude)
    }

    var localPosition: LocalPosition {
        LocalPosition(x: localX, y: localY, z: localZ)
    }
}

struct StadiumSection: Codable {
    let sectionId: String
    let sectionName: String
    let level: String
    let floor: Int
    let category: String
    let latitude: Double
    let longitude: Double
    let localX: Double
    let localY: Double
    let localZ: Double
    let boundaryPolygon: [PolygonPoint]
    let rows: RowRange
    let seatsPerRow: Int
    let totalSeats: Int
    let nearestGate: String
    let nearestConcessions: [String]
    let nearestRestrooms: [String]
    let accessibleSeating: Bool
    let viewDirection: String

    enum CodingKeys: String, CodingKey {
        case sectionId = "section_id"
        case sectionName = "section_name"
        case level, floor, category, latitude, longitude
        case localX = "local_x"
        case localY = "local_y"
        case localZ = "local_z"
        case boundaryPolygon = "boundary_polygon"
        case rows
        case seatsPerRow = "seats_per_row"
        case totalSeats = "total_seats"
        case nearestGate = "nearest_gate"
        case nearestConcessions = "nearest_concessions"
        case nearestRestrooms = "nearest_restrooms"
        case accessibleSeating = "accessible_seating"
        case viewDirection = "view_direction"
    }

    var coordinate: Coordinate {
        Coordinate(latitude: latitude, longitude: longitude)
    }

    var localPosition: LocalPosition {
        LocalPosition(x: localX, y: localY, z: localZ)
    }
}

struct PolygonPoint: Codable {
    let x: Double
    let y: Double
}

struct RowRange: Codable {
    let start: Int
    let end: Int
}

struct StadiumAmenity: Codable {
    let type: String
    let id: String
    let name: String
    let floor: Int
    let levelId: String
    let latitude: Double
    let longitude: Double
    let localX: Double
    let localY: Double
    let localZ: Double
    let accessible: Bool?
    let description: String?
    // Optional fields for specific amenity types
    let gender: String?
    let familyRestroom: Bool?
    let vendors: [String]?
    let cuisineTypes: [String]?

    enum CodingKeys: String, CodingKey {
        case type, id, name, floor
        case levelId = "level_id"
        case latitude, longitude
        case localX = "local_x"
        case localY = "local_y"
        case localZ = "local_z"
        case accessible, description
        case gender
        case familyRestroom = "family_restroom"
        case vendors
        case cuisineTypes = "cuisine_types"
    }

    var coordinate: Coordinate {
        Coordinate(latitude: latitude, longitude: longitude)
    }

    var localPosition: LocalPosition {
        LocalPosition(x: localX, y: localY, z: localZ)
    }
}

struct StadiumMetadata: Codable {
    let dataVersion: String
    let lastUpdated: String
    let accuracyMeters: Double
    let dataSource: String
    let coordinateSystemNotes: String
    let dataCompleteness: String
    let notes: String

    enum CodingKeys: String, CodingKey {
        case dataVersion = "data_version"
        case lastUpdated = "last_updated"
        case accuracyMeters = "accuracy_meters"
        case dataSource = "data_source"
        case coordinateSystemNotes = "coordinate_system_notes"
        case dataCompleteness = "data_completeness"
        case notes
    }
}

// MARK: - Supporting Types

struct LocalPosition {
    let x: Double
    let y: Double
    let z: Double

    /// Calculate distance to another position
    func distance(to other: LocalPosition) -> Double {
        let dx = other.x - x
        let dy = other.y - y
        let dz = other.z - z
        return sqrt(dx*dx + dy*dy + dz*dz)
    }

    /// Calculate bearing (direction) to another position in degrees
    func bearing(to other: LocalPosition) -> Double {
        let dx = other.x - x
        let dy = other.y - y
        let radians = atan2(dy, dx)
        let degrees = radians * 180 / .pi
        return (degrees + 360).truncatingRemainder(dividingBy: 360)
    }
}
