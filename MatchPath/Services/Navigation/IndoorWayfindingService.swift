import Foundation
import CoreLocation

/// Indoor wayfinding service for navigating inside stadiums
/// Uses stadium navigation data to provide directions from gates to seats
class IndoorWayfindingService {
    static let shared = IndoorWayfindingService()

    private var stadiumDataCache: [String: StadiumNavigationData] = [:]
    private var isLoading = false
    private var loadingTask: Task<Void, Never>?

    private init() {
        // Start loading data in background
        loadingTask = Task {
            await loadStadiumDataAsync()
        }
    }

    // MARK: - Public Methods

    /// Get navigation instructions from a gate to a specific section
    func getDirections(
        from gateId: String,
        to sectionNumber: String,
        in stadiumId: String
    ) -> SeatNavigationDirections? {
        print("🔍 IndoorWayfinding: getDirections called")
        print("   - Stadium ID: \(stadiumId)")
        print("   - Gate ID: \(gateId)")
        print("   - Section: \(sectionNumber)")
        print("   - Cached stadium IDs: \(stadiumDataCache.keys.joined(separator: ", "))")

        guard let stadiumData = stadiumDataCache[stadiumId] else {
            print("❌ IndoorWayfinding: Stadium data not found for \(stadiumId)")
            print("   - Available IDs in cache: \(stadiumDataCache.keys.joined(separator: ", "))")
            return nil
        }

        print("✅ IndoorWayfinding: Stadium data found")
        print("   - Available gates: \(stadiumData.gates.map { $0.id }.joined(separator: ", "))")
        print("   - Available sections: \(stadiumData.sections.map { $0.sectionId }.joined(separator: ", "))")

        guard let gate = stadiumData.gates.first(where: { $0.id == gateId }) else {
            print("❌ IndoorWayfinding: Gate not found: \(gateId)")
            return nil
        }

        print("✅ IndoorWayfinding: Gate found: \(gate.name)")

        guard let section = stadiumData.sections.first(where: { $0.sectionId == sectionNumber }) else {
            print("❌ IndoorWayfinding: Section not found: \(sectionNumber)")
            return nil
        }

        print("✅ IndoorWayfinding: Section found: \(section.sectionName)")
        print("✅ IndoorWayfinding: Generating directions...")

        return generateDirections(from: gate, to: section, in: stadiumData)
    }

    /// Get the nearest gate for a specific section
    func getNearestGate(for sectionNumber: String, in stadiumId: String) -> StadiumGate? {
        guard let stadiumData = stadiumDataCache[stadiumId] else { return nil }
        guard let section = stadiumData.sections.first(where: { $0.sectionId == sectionNumber }) else {
            return nil
        }

        return stadiumData.gates.first(where: { $0.id == section.nearestGate })
    }

    /// Get cached stadium navigation data for a stadium ID
    func getStadiumData(for stadiumId: String) -> StadiumNavigationData? {
        return stadiumDataCache[stadiumId]
    }

    /// Get nearby amenities (restrooms, concessions) for a section
    func getNearbyAmenities(for sectionNumber: String, in stadiumId: String) -> NearbyAmenities? {
        guard let stadiumData = stadiumDataCache[stadiumId] else { return nil }
        guard let section = stadiumData.sections.first(where: { $0.sectionId == sectionNumber }) else {
            return nil
        }

        let restrooms = section.nearestRestrooms.compactMap { restroomId in
            stadiumData.amenities.first(where: { $0.id == restroomId })
        }

        let concessions = section.nearestConcessions.compactMap { concessionId in
            stadiumData.amenities.first(where: { $0.id == concessionId })
        }

        return NearbyAmenities(restrooms: restrooms, concessions: concessions)
    }

    /// Calculate compass bearing from current position to section
    func getCompassBearing(
        from userPosition: LocalPosition,
        to sectionNumber: String,
        in stadiumId: String
    ) -> Double? {
        guard let stadiumData = stadiumDataCache[stadiumId] else { return nil }
        guard let section = stadiumData.sections.first(where: { $0.sectionId == sectionNumber }) else {
            return nil
        }

        return userPosition.bearing(to: section.localPosition)
    }

    // MARK: - Private Methods

    /// Load stadium data asynchronously
    private func loadStadiumDataAsync() async {
        guard !isLoading else {
            print("⚠️ IndoorWayfinding: Already loading, skipping duplicate load")
            return
        }
        isLoading = true

        print("🔄 IndoorWayfinding: Starting async data load...")

        // Load Hard Rock Stadium data
        if let hardRockData = await loadStadiumJSONAsync(filename: "hard_rock_stadium_sample") {
            stadiumDataCache["hard-rock-stadium"] = hardRockData
            stadiumDataCache["stadium-001"] = hardRockData
            stadiumDataCache["stadium-hardrock"] = hardRockData // VenueData.json ID
            print("✅ IndoorWayfinding: Loaded Hard Rock Stadium data")
            print("   - Cached with IDs: hard-rock-stadium, stadium-001, stadium-hardrock")
        } else {
            print("❌ IndoorWayfinding: Failed to load Hard Rock Stadium data")
        }

        // Can add more stadiums here as JSON files become available

        isLoading = false
        print("✅ IndoorWayfinding: Data loading complete")
        print("   - Total stadiums in cache: \(stadiumDataCache.count)")
        print("   - Cache keys: \(stadiumDataCache.keys.joined(separator: ", "))")
    }

    /// Ensure data is loaded before use
    func ensureDataLoaded() async {
        print("🔍 IndoorWayfinding: ensureDataLoaded called")
        print("   - Cache empty: \(stadiumDataCache.isEmpty)")
        print("   - Is loading: \(isLoading)")

        // Always load if cache is empty, regardless of loading task status
        if stadiumDataCache.isEmpty {
            print("⚠️ IndoorWayfinding: Cache is empty, forcing load...")

            // Reset loading flag to allow fresh load
            if isLoading {
                print("⚠️ IndoorWayfinding: Resetting isLoading flag")
                isLoading = false
            }

            await loadStadiumDataAsync()

            print("🔍 IndoorWayfinding: Load attempt complete")
            print("   - Cache has \(stadiumDataCache.count) stadium(s)")
            if !stadiumDataCache.isEmpty {
                print("   - Cache keys: \(stadiumDataCache.keys.joined(separator: ", "))")
            }
        } else {
            print("✅ IndoorWayfinding: Cache has \(stadiumDataCache.count) stadium(s)")
            print("   - Cache keys: \(stadiumDataCache.keys.joined(separator: ", "))")
        }
    }

    /// Async version of JSON loader for better performance
    private func loadStadiumJSONAsync(filename: String) async -> StadiumNavigationData? {
        print("🔍 IndoorWayfinding: Attempting to load \(filename).json")

        // Try to load from app bundle
        print("🔍 IndoorWayfinding: Trying app bundle...")
        if let url = Bundle.main.url(forResource: filename, withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let stadiumData = try decoder.decode(StadiumNavigationData.self, from: data)
                print("✅ IndoorWayfinding: Loaded from bundle successfully")
                return stadiumData
            } catch {
                print("❌ IndoorWayfinding: Failed to decode from bundle \(filename): \(error)")
            }
        } else {
            print("⚠️ IndoorWayfinding: Stadium data file not found in bundle: \(filename)")
        }

        // Final fallback: embedded hardcoded data
        print("🔍 IndoorWayfinding: Trying embedded fallback data...")
        if let embedded = EmbeddedStadiumNavData.load(stadiumId: "hard-rock-stadium") {
            print("✅ IndoorWayfinding: Loaded embedded fallback data")
            return embedded
        }

        return nil
    }

    private func generateDirections(
        from gate: StadiumGate,
        to section: StadiumSection,
        in stadiumData: StadiumNavigationData
    ) -> SeatNavigationDirections {
        let distance = gate.localPosition.distance(to: section.localPosition)
        let bearing = gate.localPosition.bearing(to: section.localPosition)

        // Determine if need to change floors
        let needsFloorChange = gate.floor != section.floor

        // Generate step-by-step instructions
        var steps: [NavigationStep] = []

        // Step 1: Enter through gate
        steps.append(NavigationStep(
            icon: "door.left.hand.open",
            title: "Enter at \(gate.name)",
            description: gate.description,
            distance: 0
        ))

        // Step 2: Change floor if needed
        if needsFloorChange {
            let levelInfo = stadiumData.levels.first(where: { $0.levelId == section.level })
            let floorChange = section.floor - gate.floor

            if floorChange > 0 {
                steps.append(NavigationStep(
                    icon: "arrow.up",
                    title: "Go up to \(levelInfo?.levelName ?? "Level \(section.floor)")",
                    description: "Take escalator or stairs up \(floorChange) level(s)",
                    distance: 10
                ))
            } else {
                steps.append(NavigationStep(
                    icon: "arrow.down",
                    title: "Go down to \(levelInfo?.levelName ?? "Level \(section.floor)")",
                    description: "Take escalator or stairs down \(abs(floorChange)) level(s)",
                    distance: 10
                ))
            }
        }

        // Step 3: Navigate to section
        let direction = cardinalDirection(from: bearing)
        let directionIcon = getDirectionIcon(for: direction)
        steps.append(NavigationStep(
            icon: directionIcon,
            title: "Walk \(direction)",
            description: "Follow signs to Section \(section.sectionId)",
            distance: Int(distance)
        ))

        // Step 4: Find section
        steps.append(NavigationStep(
            icon: "checkmark.circle.fill",
            title: "Arrive at \(section.sectionName)",
            description: "Look for section markers - Rows \(section.rows.start)-\(section.rows.end)",
            distance: 0
        ))

        return SeatNavigationDirections(
            stadiumName: stadiumData.stadiumName,
            gate: gate,
            section: section,
            totalDistance: Int(distance) + (needsFloorChange ? 10 : 0),
            estimatedTimeMinutes: calculateWalkingTime(distance: distance),
            compassBearing: bearing,
            steps: steps,
            nearbyRestrooms: section.nearestRestrooms.compactMap { id in
                stadiumData.amenities.first(where: { $0.id == id })
            },
            nearbyConcessions: section.nearestConcessions.compactMap { id in
                stadiumData.amenities.first(where: { $0.id == id })
            }
        )
    }

    private func cardinalDirection(from bearing: Double) -> String {
        switch bearing {
        case 0..<22.5, 337.5...360: return "North"
        case 22.5..<67.5: return "Northeast"
        case 67.5..<112.5: return "East"
        case 112.5..<157.5: return "Southeast"
        case 157.5..<202.5: return "South"
        case 202.5..<247.5: return "Southwest"
        case 247.5..<292.5: return "West"
        case 292.5..<337.5: return "Northwest"
        default: return "Forward"
        }
    }

    private func calculateWalkingTime(distance: Double) -> Int {
        // Average walking speed: 1.4 m/s (indoor with crowds)
        let seconds = distance / 1.4
        return max(Int(ceil(seconds / 60)), 1) // At least 1 minute
    }

    private func getDirectionIcon(for direction: String) -> String {
        switch direction {
        case "North": return "arrow.up"
        case "Northeast": return "arrow.up.right"
        case "East": return "arrow.right"
        case "Southeast": return "arrow.down.right"
        case "South": return "arrow.down"
        case "Southwest": return "arrow.down.left"
        case "West": return "arrow.left"
        case "Northwest": return "arrow.up.left"
        default: return "arrow.forward"
        }
    }
}

// MARK: - Models

struct SeatNavigationDirections {
    let stadiumName: String
    let gate: StadiumGate
    let section: StadiumSection
    let totalDistance: Int // meters
    let estimatedTimeMinutes: Int
    let compassBearing: Double // degrees
    let steps: [NavigationStep]
    let nearbyRestrooms: [StadiumAmenity]
    let nearbyConcessions: [StadiumAmenity]
}

struct NavigationStep {
    let icon: String
    let title: String
    let description: String
    let distance: Int // meters
}

struct NearbyAmenities {
    let restrooms: [StadiumAmenity]
    let concessions: [StadiumAmenity]
}
