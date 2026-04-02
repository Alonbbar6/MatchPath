import Foundation

/// Service to load venue data from local JSON file
/// Provides offline-first venue lookup for schedule generation
class VenueDataLoader {
    static let shared = VenueDataLoader()

    private init() {}

    // MARK: - Data Models for JSON Parsing

    struct VenueData: Codable {
        let stadiums: [StadiumData]
    }

    struct StadiumData: Codable {
        let id: String
        let name: String
        let city: String
        let country: String
        let address: String
        let latitude: Double
        let longitude: Double
        let capacity: Int
        let timezone: String
        let entryGates: [EntryGateData]
        let foodOrderingAppScheme: String?
        let foodOrderingAppName: String?
        let foodOrderingWebURL: String?
    }

    struct EntryGateData: Codable {
        let id: String
        let name: String
        let latitude: Double
        let longitude: Double
        let recommendedFor: [String]
        let capacity: Int
        let currentCrowdLevel: String
    }

    // MARK: - Public API

    /// Load venue data from JSON file
    func loadData() -> VenueData? {
        guard let url = Bundle.main.url(forResource: "VenueData", withExtension: "json") else {
            print("❌ VenueData.json not found in bundle")
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let venueData = try decoder.decode(VenueData.self, from: data)
            print("✅ Loaded \(venueData.stadiums.count) venues from JSON")
            return venueData
        } catch {
            print("❌ Error loading venue data: \(error)")
            return nil
        }
    }

    /// Load all venues as Stadium models
    func loadVenues() -> [Stadium] {
        guard let data = loadData() else { return [] }

        return data.stadiums.map { stadiumData in
            Stadium(
                id: stadiumData.id,
                name: stadiumData.name,
                city: stadiumData.city,
                address: stadiumData.address,
                coordinate: Coordinate(
                    latitude: stadiumData.latitude,
                    longitude: stadiumData.longitude
                ),
                capacity: stadiumData.capacity,
                entryGates: stadiumData.entryGates.map { gateData in
                    EntryGate(
                        id: gateData.id,
                        name: gateData.name,
                        coordinate: Coordinate(
                            latitude: gateData.latitude,
                            longitude: gateData.longitude
                        ),
                        recommendedFor: gateData.recommendedFor,
                        capacity: gateData.capacity,
                        currentCrowdLevel: CrowdLevel(rawValue: gateData.currentCrowdLevel.capitalized) ?? .moderate
                    )
                },
                foodOrderingAppScheme: stadiumData.foodOrderingAppScheme,
                foodOrderingAppName: stadiumData.foodOrderingAppName,
                foodOrderingWebURL: stadiumData.foodOrderingWebURL
            )
        }
    }

    /// Find a venue by ID
    func venue(withId id: String) -> Stadium? {
        loadVenues().first { $0.id == id }
    }

    /// Search venues by name
    func searchVenues(query: String) -> [Stadium] {
        let venues = loadVenues()
        guard !query.isEmpty else { return venues }
        let lowered = query.lowercased()
        return venues.filter {
            $0.name.lowercased().contains(lowered) ||
            $0.city.lowercased().contains(lowered)
        }
    }
}
