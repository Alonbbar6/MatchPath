import Foundation

/// Minimal embedded navigation data for demo purposes.
/// Replaces the deleted hard_rock_stadium_sample.json.
struct EmbeddedStadiumNavData {

    static func load(stadiumId: String) -> StadiumNavigationData? {
        switch stadiumId {
        case "hard-rock-stadium", "stadium-001", "stadium-hardrock":
            return hardRockStadium()
        default:
            return nil
        }
    }

    private static func hardRockStadium() -> StadiumNavigationData {
        StadiumNavigationData(
            stadiumId: "hard-rock-stadium",
            stadiumName: "Hard Rock Stadium",
            officialName: "Hard Rock Stadium",
            location: StadiumLocation(
                address: "347 Don Shula Dr",
                city: "Miami Gardens",
                stateProvince: "FL",
                country: "USA",
                postalCode: "33056"
            ),
            capacity: 65326,
            referencePoint: ReferencePoint(
                latitude: 25.9580,
                longitude: -80.2389,
                altitude: 3.0,
                description: "Stadium center field",
                coordinateSystem: "WGS84"
            ),
            localCoordinateSystem: LocalCoordinateSystem(
                origin: ReferencePoint(
                    latitude: 25.9580,
                    longitude: -80.2389,
                    altitude: 3.0,
                    description: "Center of field",
                    coordinateSystem: "WGS84"
                ),
                units: "meters",
                rotation: 17.0,
                description: "Local XY coordinate system centered on field, rotated 17 degrees CW from north"
            ),
            levels: [
                StadiumLevel(
                    levelId: "level-100", levelName: "100 Level",
                    floor: 1, elevationMeters: 0.0,
                    description: "Lower bowl"
                ),
                StadiumLevel(
                    levelId: "level-200", levelName: "200 Level",
                    floor: 2, elevationMeters: 8.0,
                    description: "Club level"
                ),
                StadiumLevel(
                    levelId: "level-300", levelName: "300 Level",
                    floor: 3, elevationMeters: 20.0,
                    description: "Upper bowl"
                ),
            ],
            gates: [
                StadiumGate(
                    id: "gate-north", name: "North Gate", type: "main",
                    latitude: 25.9600, longitude: -80.2389,
                    floor: 1, levelId: "level-100",
                    localX: 0, localY: 120, localZ: 0,
                    servesSections: ["101", "102", "103", "104", "105", "106", "107", "108"],
                    accessible: true, description: "Main north entrance"
                ),
                StadiumGate(
                    id: "gate-south", name: "South Gate", type: "main",
                    latitude: 25.9560, longitude: -80.2389,
                    floor: 1, levelId: "level-100",
                    localX: 0, localY: -120, localZ: 0,
                    servesSections: ["142", "143", "144", "145", "146", "147", "148", "149", "150"],
                    accessible: true, description: "Main south entrance"
                ),
                StadiumGate(
                    id: "gate-east", name: "East Gate", type: "main",
                    latitude: 25.9580, longitude: -80.2369,
                    floor: 1, levelId: "level-100",
                    localX: 120, localY: 0, localZ: 0,
                    servesSections: ["129", "130", "131", "132", "133", "134", "135"],
                    accessible: true, description: "East side entrance"
                ),
                StadiumGate(
                    id: "gate-west", name: "West Gate", type: "main",
                    latitude: 25.9580, longitude: -80.2409,
                    floor: 1, levelId: "level-100",
                    localX: -120, localY: 0, localZ: 0,
                    servesSections: ["156", "196", "197"],
                    accessible: true, description: "West side entrance"
                ),
            ],
            sections: [
                StadiumSection(
                    sectionId: "101", sectionName: "Section 101",
                    level: "level-100", floor: 1, category: "standard",
                    latitude: 25.9595, longitude: -80.2405,
                    localX: -80, localY: 90, localZ: 0,
                    boundaryPolygon: [], rows: RowRange(start: 1, end: 30),
                    seatsPerRow: 20, totalSeats: 600,
                    nearestGate: "gate-north",
                    nearestConcessions: ["concession-n1"],
                    nearestRestrooms: ["restroom-n1"],
                    accessibleSeating: true, viewDirection: "south"
                ),
                StadiumSection(
                    sectionId: "118", sectionName: "Section 118",
                    level: "level-100", floor: 1, category: "standard",
                    latitude: 25.9595, longitude: -80.2375,
                    localX: 60, localY: 90, localZ: 0,
                    boundaryPolygon: [], rows: RowRange(start: 1, end: 30),
                    seatsPerRow: 22, totalSeats: 660,
                    nearestGate: "gate-north",
                    nearestConcessions: ["concession-n2"],
                    nearestRestrooms: ["restroom-n1"],
                    accessibleSeating: true, viewDirection: "south"
                ),
                StadiumSection(
                    sectionId: "132", sectionName: "Section 132",
                    level: "level-100", floor: 1, category: "standard",
                    latitude: 25.9580, longitude: -80.2365,
                    localX: 110, localY: 0, localZ: 0,
                    boundaryPolygon: [], rows: RowRange(start: 1, end: 30),
                    seatsPerRow: 20, totalSeats: 600,
                    nearestGate: "gate-east",
                    nearestConcessions: ["concession-e1"],
                    nearestRestrooms: ["restroom-e1"],
                    accessibleSeating: true, viewDirection: "west"
                ),
                StadiumSection(
                    sectionId: "146", sectionName: "Section 146",
                    level: "level-100", floor: 1, category: "standard",
                    latitude: 25.9565, longitude: -80.2389,
                    localX: 0, localY: -100, localZ: 0,
                    boundaryPolygon: [], rows: RowRange(start: 1, end: 30),
                    seatsPerRow: 22, totalSeats: 660,
                    nearestGate: "gate-south",
                    nearestConcessions: ["concession-s1"],
                    nearestRestrooms: ["restroom-s1"],
                    accessibleSeating: true, viewDirection: "north"
                ),
            ],
            amenities: [
                StadiumAmenity(
                    type: "restroom", id: "restroom-n1",
                    name: "North Restrooms", floor: 1,
                    levelId: "level-100",
                    latitude: 25.9597, longitude: -80.2395,
                    localX: -30, localY: 100, localZ: 0,
                    accessible: true, description: "Near north gate",
                    gender: "unisex", familyRestroom: true,
                    vendors: nil, cuisineTypes: nil
                ),
                StadiumAmenity(
                    type: "concession", id: "concession-n1",
                    name: "North Concessions", floor: 1,
                    levelId: "level-100",
                    latitude: 25.9596, longitude: -80.2400,
                    localX: -50, localY: 95, localZ: 0,
                    accessible: true, description: "Food and drinks",
                    gender: nil, familyRestroom: nil,
                    vendors: ["Burgers", "Pizza"],
                    cuisineTypes: ["American"]
                ),
                StadiumAmenity(
                    type: "restroom", id: "restroom-e1",
                    name: "East Restrooms", floor: 1,
                    levelId: "level-100",
                    latitude: 25.9580, longitude: -80.2370,
                    localX: 100, localY: 10, localZ: 0,
                    accessible: true, description: "Near east gate",
                    gender: "unisex", familyRestroom: false,
                    vendors: nil, cuisineTypes: nil
                ),
                StadiumAmenity(
                    type: "concession", id: "concession-e1",
                    name: "East Concessions", floor: 1,
                    levelId: "level-100",
                    latitude: 25.9582, longitude: -80.2368,
                    localX: 105, localY: 15, localZ: 0,
                    accessible: true, description: "East side food court",
                    gender: nil, familyRestroom: nil,
                    vendors: ["Hot Dogs", "Nachos"],
                    cuisineTypes: ["American"]
                ),
                StadiumAmenity(
                    type: "restroom", id: "restroom-s1",
                    name: "South Restrooms", floor: 1,
                    levelId: "level-100",
                    latitude: 25.9562, longitude: -80.2389,
                    localX: 0, localY: -110, localZ: 0,
                    accessible: true, description: "Near south gate",
                    gender: "unisex", familyRestroom: true,
                    vendors: nil, cuisineTypes: nil
                ),
                StadiumAmenity(
                    type: "concession", id: "concession-s1",
                    name: "South Concessions", floor: 1,
                    levelId: "level-100",
                    latitude: 25.9563, longitude: -80.2393,
                    localX: -20, localY: -105, localZ: 0,
                    accessible: true, description: "South side food",
                    gender: nil, familyRestroom: nil,
                    vendors: ["Tacos", "Drinks"],
                    cuisineTypes: ["Mexican"]
                ),
                StadiumAmenity(
                    type: "concession", id: "concession-n2",
                    name: "Northeast Concessions", floor: 1,
                    levelId: "level-100",
                    latitude: 25.9596, longitude: -80.2380,
                    localX: 40, localY: 95, localZ: 0,
                    accessible: true, description: "Northeast food area",
                    gender: nil, familyRestroom: nil,
                    vendors: ["Sushi", "Salads"],
                    cuisineTypes: ["Japanese", "Healthy"]
                ),
            ],
            metadata: StadiumMetadata(
                dataVersion: "1.0",
                lastUpdated: "2026-02-01",
                accuracyMeters: 2.0,
                dataSource: "Embedded fallback",
                coordinateSystemNotes: "Local XY in meters, origin at center field",
                dataCompleteness: "Minimal demo set with 4 gates, 4 sections",
                notes: "Hardcoded for park demo mode testing"
            )
        )
    }
}
