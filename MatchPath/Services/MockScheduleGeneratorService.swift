import Foundation
import CoreLocation

/// Mock implementation of schedule generation for demo/testing without API calls
class MockScheduleGeneratorService {
    static let shared = MockScheduleGeneratorService()

    private init() {}

    /// Generate a realistic mock schedule without API calls
    func generateSchedule(
        for game: SportingEvent,
        from userLocation: UserLocation,
        sectionNumber: String? = nil,
        preference: ArrivalPreference,
        transportationMode: TransportationMode = .publicTransit,
        parkingSpot: ParkingSpot? = nil,
        foodOrder: FoodOrder? = nil
    ) async throws -> GameSchedule {
        // Simulate API delay for realism
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds

        // Get mock route with realistic travel time based on stadium
        let mockRoute = createMockRoute(to: game.stadium, from: userLocation)

        // Select best gate based on mock crowd data
        let gate = selectMockGate(for: game.stadium, preference: preference)

        // Calculate target arrival based on preference
        let targetArrival = calculateTargetArrival(
            kickoffTime: game.kickoffTime,
            preference: preference
        )

        // Create parking reservation if driving and parking spot provided
        var parkingReservation: ParkingReservation? = nil
        if transportationMode == .driving, let spot = parkingSpot {
            parkingReservation = ParkingReservation(
                id: "res-\(UUID().uuidString.prefix(8))",
                parkingSpot: spot,
                startTime: targetArrival.addingTimeInterval(-1800), // 30 min before arrival
                endTime: game.kickoffTime.addingTimeInterval(10800), // 3 hours after kickoff
                confirmationCode: "DEMO-\(Int.random(in: 1000...9999))",
                qrCode: nil,
                status: .confirmed,
                createdAt: Date()
            )
        }

        // Create schedule steps with actual transportation mode, parking, and food
        let steps = createMockScheduleSteps(
            game: game,
            userLocation: userLocation,
            route: mockRoute,
            gate: gate,
            targetArrival: targetArrival,
            preference: preference,
            transportationMode: transportationMode,
            parkingSpot: parkingSpot,
            foodOrder: foodOrder
        )

        // Calculate mock confidence score
        let confidenceScore = calculateMockConfidence(preference: preference, gate: gate)

        return GameSchedule(
            id: UUID().uuidString,
            game: game,
            userLocation: userLocation,
            sectionNumber: sectionNumber,
            scheduleSteps: steps,
            recommendedGate: gate,
            purchaseDate: Date(),
            arrivalPreference: preference,
            transportationMode: transportationMode,
            parkingReservation: parkingReservation,
            foodOrder: foodOrder,
            confidenceScore: confidenceScore
        )
    }

    // MARK: - Mock Data Generation

    private func createMockRoute(to stadium: Stadium, from location: UserLocation) -> MockRouteInfo {
        // Calculate realistic travel time based on distance
        let distance = calculateDistance(
            from: location.coordinate,
            to: stadium.coordinate
        )

        // Base travel time: ~2 min per km for transit
        let baseTime = Int(distance * 2)

        // Add random traffic delay (0-15 minutes)
        let trafficDelay = Int.random(in: 0...15)

        return MockRouteInfo(
            travelTimeMinutes: baseTime,
            trafficDelayMinutes: trafficDelay,
            distanceKm: distance,
            mode: "transit"
        )
    }

    private func selectMockGate(for stadium: Stadium, preference: ArrivalPreference) -> EntryGate {
        // For early arrivers, recommend less crowded gates
        switch preference {
        case .relaxed:
            // Prefer gates with highest capacity (less crowded early)
            return stadium.entryGates.max(by: { $0.capacity < $1.capacity }) ?? stadium.entryGates[0]
        case .balanced:
            // Middle capacity gate
            return stadium.entryGates[min(1, stadium.entryGates.count - 1)]
        case .efficient:
            // Closest gate, regardless of crowds
            return stadium.entryGates.first ?? stadium.entryGates[0]
        }
    }

    private func calculateTargetArrival(kickoffTime: Date, preference: ArrivalPreference) -> Date {
        let minutesBeforeKickoff: Int

        switch preference {
        case .relaxed:
            minutesBeforeKickoff = 120 // 2 hours early
        case .balanced:
            minutesBeforeKickoff = 90  // 1.5 hours early
        case .efficient:
            minutesBeforeKickoff = 60  // 1 hour early
        }

        return kickoffTime.addingTimeInterval(-Double(minutesBeforeKickoff * 60))
    }

    private func createMockScheduleSteps(
        game: SportingEvent,
        userLocation: UserLocation,
        route: MockRouteInfo,
        gate: EntryGate,
        targetArrival: Date,
        preference: ArrivalPreference,
        transportationMode: TransportationMode = .publicTransit,
        parkingSpot: ParkingSpot? = nil,
        foodOrder: FoodOrder? = nil
    ) -> [ScheduleStep] {
        var steps: [ScheduleStep] = []

        // Work backwards from target arrival

        // Step 7: Settle in (30 min before kickoff)
        let settleTime = game.kickoffTime.addingTimeInterval(-30 * 60)
        steps.append(ScheduleStep(
            id: UUID().uuidString,
            scheduledTime: settleTime,
            title: "Settle In & Enjoy",
            description: "Find your seat, soak in the atmosphere, and get ready for an amazing match!",
            icon: "checkmark.seal.fill",
            estimatedDuration: 30,
            stepType: .milestone
        ))

        // Step 6: Find seat (45 min before kickoff)
        let findSeatTime = game.kickoffTime.addingTimeInterval(-45 * 60)
        steps.append(ScheduleStep(
            id: UUID().uuidString,
            scheduledTime: findSeatTime,
            title: "Find Your Seat",
            description: "Navigate to your section. Check your ticket for seat details.",
            icon: "map.fill",
            estimatedDuration: 10,
            stepType: .seating
        ))

        // Step 5: Food pickup OR generic refreshments
        if let food = foodOrder {
            // Use actual food order
            let foodTime = food.pickupTime
            steps.append(ScheduleStep(
                id: UUID().uuidString,
                scheduledTime: foodTime,
                title: "Pick Up Pre-Ordered Food",
                description: "Pick up at \(food.vendorLocation). Confirmation: \(food.confirmationCode)",
                icon: "takeoutbag.and.cup.and.straw.fill",
                estimatedDuration: 5,
                stepType: .foodPickup
            ))
        } else if preference == .relaxed {
            // Generic refreshment suggestion
            let refreshmentTime = game.kickoffTime.addingTimeInterval(-55 * 60)
            steps.append(ScheduleStep(
                id: UUID().uuidString,
                scheduledTime: refreshmentTime,
                title: "Grab Food & Drinks",
                description: "Beat the rush! Concession stands are less crowded now.",
                icon: "cup.and.saucer.fill",
                estimatedDuration: 10,
                stepType: .milestone
            ))
        }

        // Step 4: Security (based on preference)
        let securityBuffer = preference == .relaxed ? 75 : preference == .balanced ? 65 : 60
        let securityTime = game.kickoffTime.addingTimeInterval(-Double(securityBuffer * 60))
        let crowdLevel = preference == .efficient ? "⚠️ High crowd level expected" : preference == .balanced ? "Moderate crowds" : "Low crowds"

        steps.append(ScheduleStep(
            id: UUID().uuidString,
            scheduledTime: securityTime,
            title: "Enter Stadium",
            description: "Security screening at \(gate.name). \(crowdLevel). Have your ticket ready!",
            icon: "checkmark.shield.fill",
            estimatedDuration: preference == .efficient ? 20 : 15,
            stepType: .entry
        ))

        // Step 3: Arrive at stadium
        let arrivalTime = securityTime.addingTimeInterval(-5 * 60)
        steps.append(ScheduleStep(
            id: UUID().uuidString,
            scheduledTime: arrivalTime,
            title: "Arrive at Stadium",
            description: "Walk to \(gate.name). Look for signage and follow the crowd!",
            icon: "building.2.fill",
            estimatedDuration: 5,
            stepType: .arrival
        ))

        // Step 2-3: Transportation (varies by mode)
        var transitTime: Date
        var departureTime: Date

        if transportationMode == .driving, let parking = parkingSpot {
            // Add parking steps
            let walkToStadiumTime = arrivalTime.addingTimeInterval(-10 * 60) // 10 min walk from parking
            steps.append(ScheduleStep(
                id: UUID().uuidString,
                scheduledTime: walkToStadiumTime,
                title: "Walk to Stadium",
                description: "Walk from \(parking.name) to stadium. About \(parking.walkingTimeToStadium) minute walk.",
                icon: "figure.walk",
                estimatedDuration: parking.walkingTimeToStadium,
                stepType: .transit
            ))

            let parkTime = walkToStadiumTime.addingTimeInterval(-5 * 60) // 5 min to park
            steps.append(ScheduleStep(
                id: UUID().uuidString,
                scheduledTime: parkTime,
                title: "Park Vehicle",
                description: "Park at \(parking.name). Confirmation: \(parking.id.prefix(8)). Remember your spot!",
                icon: "parkingsign.circle.fill",
                estimatedDuration: 5,
                stepType: .parking
            ))

            transitTime = parkTime.addingTimeInterval(-Double(route.travelTimeMinutes * 60))
            let trafficNote = route.trafficDelayMinutes > 5 ? " ⚠️ +\(route.trafficDelayMinutes) min traffic delay" : ""
            steps.append(ScheduleStep(
                id: UUID().uuidString,
                scheduledTime: transitTime,
                title: "Drive to Parking",
                description: "Drive to \(parking.name). Estimated: \(route.travelTimeMinutes) min.\(trafficNote)",
                icon: "car.fill",
                estimatedDuration: route.travelTimeMinutes,
                stepType: .transit
            ))

            departureTime = transitTime.addingTimeInterval(-5 * 60)
        } else {
            // Public transit, rideshare, or walking
            transitTime = arrivalTime.addingTimeInterval(-Double(route.travelTimeMinutes * 60))
            let trafficNote = route.trafficDelayMinutes > 5 ? " ⚠️ +\(route.trafficDelayMinutes) min traffic delay" : ""

            let (icon, title, description) = getTransportationDetails(
                mode: transportationMode,
                stadium: game.stadium.name,
                duration: route.travelTimeMinutes,
                trafficNote: trafficNote
            )

            steps.append(ScheduleStep(
                id: UUID().uuidString,
                scheduledTime: transitTime,
                title: title,
                description: description,
                icon: icon,
                estimatedDuration: route.travelTimeMinutes,
                stepType: .transit
            ))

            departureTime = transitTime.addingTimeInterval(-5 * 60)
        }

        // Step 1: Depart from location
        steps.append(ScheduleStep(
            id: UUID().uuidString,
            scheduledTime: departureTime,
            title: "Leave \(userLocation.name)",
            description: "Time to go! Grab your tickets, ID, and essentials. Check the weather!",
            icon: "figure.walk.departure",
            estimatedDuration: 5,
            stepType: .departure
        ))

        // Reverse to get chronological order
        return steps.reversed()
    }

    private func calculateDistance(from: Coordinate, to: Coordinate) -> Double {
        // Haversine formula for realistic distance
        let lat1 = from.latitude * .pi / 180
        let lon1 = from.longitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let lon2 = to.longitude * .pi / 180

        let dLat = lat2 - lat1
        let dLon = lon2 - lon1

        let a = sin(dLat/2) * sin(dLat/2) +
                cos(lat1) * cos(lat2) *
                sin(dLon/2) * sin(dLon/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        let radius = 6371.0 // Earth's radius in km

        return radius * c
    }

    private func calculateMockConfidence(preference: ArrivalPreference, gate: EntryGate) -> Int {
        var score = 85 // Base score for mock data

        // Bonus for arrival preference
        switch preference {
        case .relaxed:
            score += 10
        case .balanced:
            score += 5
        case .efficient:
            score += 0
        }

        // Penalty for crowd level
        switch gate.currentCrowdLevel {
        case .clear:
            score += 5
        case .moderate:
            score += 0
        case .crowded:
            score -= 5
        case .avoid:
            score -= 10
        }

        return min(100, max(70, score))
    }
}

// MARK: - Supporting Types

private struct MockRouteInfo {
    let travelTimeMinutes: Int
    let trafficDelayMinutes: Int
    let distanceKm: Double
    let mode: String
}

// MARK: - Transportation Helper

private func getTransportationDetails(
    mode: TransportationMode,
    stadium: String,
    duration: Int,
    trafficNote: String
) -> (icon: String, title: String, description: String) {
    switch mode {
    case .publicTransit:
        return (
            icon: "tram.fill",
            title: "Take Public Transit",
            description: "Take transit to \(stadium). Estimated time: \(duration) min.\(trafficNote)"
        )
    case .rideshare:
        return (
            icon: "car.circle.fill",
            title: "Take Rideshare",
            description: "Request Uber/Lyft to \(stadium). Estimated: \(duration) min.\(trafficNote)"
        )
    case .walking:
        return (
            icon: "figure.walk",
            title: "Walk to Stadium",
            description: "Walk to \(stadium). Estimated: \(duration) min. Wear comfortable shoes!"
        )
    case .driving:
        return (
            icon: "car.fill",
            title: "Drive",
            description: "Drive to \(stadium). Estimated: \(duration) min.\(trafficNote)"
        )
    }
}
