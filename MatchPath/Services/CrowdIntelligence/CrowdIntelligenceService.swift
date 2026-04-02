import Foundation
import CoreLocation

/// Service for estimating and tracking crowd levels along routes and at venues
/// Now enhanced with REAL transit data from Transit Land API
class CrowdIntelligenceService {
    static let shared = CrowdIntelligenceService()

    // MARK: - Services
    private let transitService = TransitCrowdDataService()

    private init() {}

    // MARK: - Public Methods

    /// Estimate crowd level for a specific route at a given time
    /// Uses traffic data as a proxy for crowd density
    /// - Parameters:
    ///   - route: The route to analyze
    ///   - departureTime: When the journey will start
    /// - Returns: Crowd intensity estimate
    func estimateCrowdLevel(
        for route: RouteInfo,
        at departureTime: Date
    ) async -> CrowdIntensityLevel {
        // Calculate crowd level based on traffic delay
        let trafficDelay = route.trafficDelayMinutes

        // More delay = higher crowds
        switch trafficDelay {
        case 0..<5:
            return .low
        case 5..<10:
            return .moderate
        case 10..<20:
            return .high
        default:
            return .veryHigh
        }
    }

    /// Get crowd forecast for a stadium at a specific time
    /// NOW WITH REAL TRANSIT DATA!
    /// - Parameters:
    ///   - stadium: The stadium to check
    ///   - time: The time to check (usually kickoff time)
    /// - Returns: Crowd forecast for the stadium area
    func getStadiumCrowdForecast(
        for stadium: Stadium,
        at time: Date
    ) async -> StadiumCrowdForecast {

        print("🎯 CrowdIntelligence: Generating forecast for \(stadium.name)")

        // STEP 1: Time-based prediction (baseline)
        let hoursUntilEvent = time.timeIntervalSinceNow / 3600
        let timeBasedIntensity: Double

        switch hoursUntilEvent {
        case ...(-0.5):
            timeBasedIntensity = 0.3  // After kickoff - crowds dispersing
        case (-0.5)..<0:
            timeBasedIntensity = 1.0  // Just before kickoff - peak crowds
        case 0..<0.5:
            timeBasedIntensity = 0.95 // 30 min before - very high
        case 0.5..<1.0:
            timeBasedIntensity = 0.8  // 30-60 min before - high
        case 1.0..<2.0:
            timeBasedIntensity = 0.6  // 1-2 hours before - building
        case 2.0..<3.0:
            timeBasedIntensity = 0.4  // 2-3 hours before - moderate
        default:
            timeBasedIntensity = 0.2  // More than 3 hours before - low
        }

        print("🎯 CrowdIntelligence: Time-based intensity: \(timeBasedIntensity)")

        // STEP 2: Get REAL transit data
        var transitIntensity: Double = 0.5  // Default neutral
        var transitConfidence: Double = 0.0

        do {
            let transitData = try await transitService.getTransitBasedCrowdLevel(
                near: stadium.coordinate,
                radiusMeters: 1000
            )

            // Map transit crowd level to intensity
            switch transitData.crowdLevel {
            case .clear:
                transitIntensity = 0.2
            case .moderate:
                transitIntensity = 0.5
            case .crowded:
                transitIntensity = 0.75
            case .avoid:
                transitIntensity = 0.95
            }

            transitConfidence = transitData.confidence

            print("🚇 CrowdIntelligence: Transit intensity: \(transitIntensity) (confidence: \(transitConfidence))")
            print("🚇 CrowdIntelligence: Transit reasoning: \(transitData.reasoning)")

        } catch {
            print("⚠️ CrowdIntelligence: Transit data unavailable - using time-based only")
            print("   Error: \(error.localizedDescription)")
        }

        // STEP 3: Combine predictions (weighted average)
        let crowdIntensity: Double

        if transitConfidence > 0.5 {
            // High confidence transit data - give it more weight
            crowdIntensity = (timeBasedIntensity * 0.4) + (transitIntensity * 0.6)
            print("✅ CrowdIntelligence: Using transit-weighted prediction")
        } else {
            // Low confidence or no transit data - mostly use time-based
            crowdIntensity = (timeBasedIntensity * 0.8) + (transitIntensity * 0.2)
            print("✅ CrowdIntelligence: Using time-weighted prediction")
        }

        print("🎯 CrowdIntelligence: Final combined intensity: \(crowdIntensity)")

        // Update entry gate crowd levels based on overall intensity
        let gatesWithCrowds = stadium.entryGates.map { gate in
            var updatedGate = gate
            updatedGate.currentCrowdLevel = mapIntensityToUICrowdLevel(
                calculateGateCrowdIntensity(
                    baseIntensity: crowdIntensity,
                    gateCapacity: gate.capacity
                )
            )
            return updatedGate
        }

        // Find best (least crowded) gates
        let recommendedGates = gatesWithCrowds
            .sorted { $0.currentCrowdLevel.rawValue < $1.currentCrowdLevel.rawValue }
            .prefix(3)
            .map { $0 }

        return StadiumCrowdForecast(
            stadium: stadium,
            forecastTime: time,
            overallCrowdIntensity: intensityToCrowdIntensityLevel(crowdIntensity),
            entryGates: gatesWithCrowds,
            recommendedGates: Array(recommendedGates),
            peakTime: time.addingTimeInterval(-30 * 60), // 30 min before kickoff
            estimatedWaitTimeMinutes: Int(crowdIntensity * 15) // Up to 15 min wait at peak
        )
    }

    /// Score multiple routes considering both travel time and crowd levels
    /// - Parameters:
    ///   - routes: Routes to score
    ///   - departureTime: When the journey will start
    ///   - crowdWeight: How much to weight crowd avoidance (0.0-1.0), defaults to config value
    /// - Returns: Routes sorted by best score (lowest first)
    func scoreAndRankRoutes(
        _ routes: [RouteInfo],
        departureTime: Date,
        crowdWeight: Double? = nil
    ) async -> [ScoredRoute] {
        let weight = crowdWeight ?? GoogleMapsConfig.crowdAvoidanceWeight
        var scoredRoutes: [ScoredRoute] = []

        for route in routes {
            let crowdIntensity = await estimateCrowdLevel(for: route, at: departureTime)

            // Score components
            let timeScore = Double(route.travelTimeMinutes) // Lower is better
            let crowdScore = Double(crowdIntensity.rawValue) * 10.0 // Lower is better

            // Weighted total score
            let totalScore = (1.0 - weight) * timeScore + weight * crowdScore

            scoredRoutes.append(ScoredRoute(
                route: route,
                crowdIntensity: crowdIntensity,
                timeScore: timeScore,
                crowdScore: crowdScore,
                totalScore: totalScore
            ))
        }

        // Sort by best (lowest) score
        return scoredRoutes.sorted { $0.totalScore < $1.totalScore }
    }

    // MARK: - Private Helpers

    private func calculateGateCrowdIntensity(baseIntensity: Double, gateCapacity: Int) -> CrowdIntensityLevel {
        // Smaller gates get more crowded faster
        let capacityFactor = 1000.0 / Double(gateCapacity)
        let adjustedIntensity = baseIntensity * capacityFactor

        switch adjustedIntensity {
        case 0..<0.3:
            return .low
        case 0.3..<0.5:
            return .moderate
        case 0.5..<0.7:
            return .high
        case 0.7..<0.9:
            return .veryHigh
        default:
            return .extreme
        }
    }

    private func intensityToCrowdIntensityLevel(_ intensity: Double) -> CrowdIntensityLevel {
        switch intensity {
        case 0..<0.25:
            return .low
        case 0.25..<0.5:
            return .moderate
        case 0.5..<0.75:
            return .high
        case 0.75..<0.9:
            return .veryHigh
        default:
            return .extreme
        }
    }

    // Map service intensity scale to UI CrowdLevel
    private func mapIntensityToUICrowdLevel(_ intensity: CrowdIntensityLevel) -> CrowdLevel {
        switch intensity {
        case .low: return .clear
        case .moderate: return .moderate
        case .high: return .crowded
        case .veryHigh, .extreme: return .avoid
        }
    }
}

// MARK: - Models

struct StadiumCrowdForecast {
    let stadium: Stadium
    let forecastTime: Date
    // Use service's intensity type internally
    let overallCrowdIntensity: CrowdIntensityLevel
    let entryGates: [EntryGate]          // UI-level crowd already mapped per gate
    let recommendedGates: [EntryGate]
    let peakTime: Date
    let estimatedWaitTimeMinutes: Int

    // Convenience for UI when needed
    var overallUICrowdLevel: CrowdLevel {
        switch overallCrowdIntensity {
        case .low: return .clear
        case .moderate: return .moderate
        case .high: return .crowded
        case .veryHigh, .extreme: return .avoid
        }
    }

    var emoji: String {
        switch overallCrowdIntensity {
        case .low: return "🟢"
        case .moderate: return "🟡"
        case .high: return "🟠"
        case .veryHigh: return "🔴"
        case .extreme: return "🚨"
        }
    }
}

struct ScoredRoute {
    let route: RouteInfo
    let crowdIntensity: CrowdIntensityLevel
    let timeScore: Double
    let crowdScore: Double
    let totalScore: Double

    var recommendation: String {
        if crowdIntensity == .low && route.travelTimeMinutes < 30 {
            return "✨ Best route: Fast and low crowds"
        } else if crowdIntensity == .low {
            return "🌿 Peaceful route: Avoid the crowds"
        } else if route.travelTimeMinutes < 20 {
            return "⚡️ Fastest route: Some crowds expected"
        } else if crowdIntensity == .high || crowdIntensity == .veryHigh {
            return "⚠️ Crowded route: Consider alternatives"
        } else {
            return "Balanced option"
        }
    }
}

// Renamed from CrowdLevel to avoid conflict with UI CrowdLevel
enum CrowdIntensityLevel: Int, Codable {
    case low = 1
    case moderate = 2
    case high = 3
    case veryHigh = 4
    case extreme = 5

    var description: String {
        switch self {
        case .low: return "Low"
        case .moderate: return "Moderate"
        case .high: return "High"
        case .veryHigh: return "Very High"
        case .extreme: return "Extreme"
        }
    }

    var color: String {
        switch self {
        case .low: return "green"
        case .moderate: return "yellow"
        case .high: return "orange"
        case .veryHigh: return "red"
        case .extreme: return "purple"
        }
    }
}
