import Foundation

/// Service for recommending optimal entry gates based on user's section number
class GateRecommendationService {
    static let shared = GateRecommendationService()

    private init() {}

    // MARK: - Public Methods

    /// Get the best entry gate for a specific section
    /// - Parameters:
    ///   - sectionNumber: The user's section (e.g., "118", "301")
    ///   - stadium: The stadium
    ///   - crowdForecast: Current crowd forecast (optional)
    /// - Returns: Recommended gate with reasoning
    func recommendGate(
        for sectionNumber: String?,
        at stadium: Stadium,
        crowdForecast: StadiumCrowdForecast? = nil
    ) -> GateRecommendation {
        // If no section number provided, use least crowded gate
        guard let section = sectionNumber else {
            return recommendByCrowdLevel(stadium: stadium, forecast: crowdForecast)
        }

        // Find gates that serve this section
        let servingGates = stadium.entryGates.filter { gate in
            gate.recommendedFor.contains { sectionRange in
                isSectionInRange(section, range: sectionRange)
            }
        }

        if servingGates.isEmpty {
            // Fallback: Use any gate
            return recommendByCrowdLevel(stadium: stadium, forecast: crowdForecast)
        }

        // If we have crowd data, pick least crowded gate that serves this section
        if let forecast = crowdForecast {
            let gatesWithCrowds = servingGates.map { gate in
                (gate: gate, crowdLevel: forecast.entryGates.first(where: { $0.id == gate.id })?.currentCrowdLevel ?? .moderate)
            }

            let bestGate = gatesWithCrowds.min { $0.crowdLevel.rawValue < $1.crowdLevel.rawValue }

            if let best = bestGate {
                return GateRecommendation(
                    gate: best.gate,
                    reason: "Closest to Section \(section) with \(best.crowdLevel.rawValue.lowercased()) crowds",
                    crowdLevel: best.crowdLevel,
                    walkingTimeToSection: estimateWalkingTime(from: best.gate, to: section)
                )
            }
        }

        // Default: Return first gate that serves this section
        let gate = servingGates.first!
        return GateRecommendation(
            gate: gate,
            reason: "Optimal entry point for Section \(section)",
            crowdLevel: gate.currentCrowdLevel,
            walkingTimeToSection: estimateWalkingTime(from: gate, to: section)
        )
    }

    // MARK: - Private Helpers

    /// Check if a section number falls within a range string (e.g., "101-120")
    private func isSectionInRange(_ section: String, range: String) -> Bool {
        // Handle single section (e.g., "118")
        if range == section {
            return true
        }

        // Handle range (e.g., "101-120")
        let parts = range.split(separator: "-")
        guard parts.count == 2,
              let rangeStart = Int(parts[0]),
              let rangeEnd = Int(parts[1]),
              let sectionNum = Int(section) else {
            return false
        }

        return sectionNum >= rangeStart && sectionNum <= rangeEnd
    }

    /// Recommend gate based purely on crowd levels
    private func recommendByCrowdLevel(stadium: Stadium, forecast: StadiumCrowdForecast?) -> GateRecommendation {
        if let forecast = forecast, let bestGate = forecast.recommendedGates.first {
            return GateRecommendation(
                gate: bestGate,
                reason: "Least crowded gate - \(bestGate.currentCrowdLevel.rawValue.lowercased()) traffic",
                crowdLevel: bestGate.currentCrowdLevel,
                walkingTimeToSection: nil
            )
        }

        // Fallback to first gate
        let gate = stadium.entryGates.first!
        return GateRecommendation(
            gate: gate,
            reason: "Main entrance",
            crowdLevel: gate.currentCrowdLevel,
            walkingTimeToSection: nil
        )
    }

    /// Estimate walking time from gate to section (simple heuristic)
    private func estimateWalkingTime(from gate: EntryGate, to section: String) -> Int {
        // Simple heuristic:
        // - Same level: 2-5 minutes
        // - Different level: 5-8 minutes
        // This would be improved with actual indoor navigation data

        // Extract level from section number (e.g., "301" = level 300)
        guard let sectionNum = Int(section) else { return 5 }

        let sectionLevel = sectionNum / 100

        // Most gates serve level 100 (ground level)
        if sectionLevel == 1 {
            return 3 // Quick walk, same level
        } else if sectionLevel == 2 {
            return 6 // One level up
        } else {
            return 8 // Two levels up
        }
    }
}

// MARK: - Models

struct GateRecommendation {
    let gate: EntryGate
    let reason: String
    let crowdLevel: CrowdLevel
    let walkingTimeToSection: Int? // minutes

    var displayReason: String {
        if let walkTime = walkingTimeToSection {
            return "\(reason) • \(walkTime) min walk to your seat"
        }
        return reason
    }
}
