import Foundation
import CoreLocation

/// Service that generates custom game-day schedules based on user location and preferences
/// Now with REAL Google Maps integration and crowd-avoiding routing!
class ScheduleGeneratorService {
    static let shared = ScheduleGeneratorService()

    private let geocodingService = GoogleGeocodingService.shared
    private let directionsService = GoogleDirectionsService.shared
    private let crowdService = CrowdIntelligenceService.shared
    private let gateService = GateRecommendationService.shared

    private init() {}

    /// Generate a complete game-day schedule with real-time traffic and crowd intelligence
    func generateSchedule(
        for game: SportingEvent,
        from userLocation: UserLocation,
        sectionNumber: String? = nil,
        preference: ArrivalPreference,
        transportationMode: TransportationMode = .publicTransit,
        parkingSpot: ParkingSpot? = nil,
        foodOrder: FoodOrder? = nil
    ) async throws -> GameSchedule {
        // Use mock mode if enabled (for demo/testing without APIs)
        if GoogleMapsConfig.useMockMode {
            return try await MockScheduleGeneratorService.shared.generateSchedule(
                for: game,
                from: userLocation,
                sectionNumber: sectionNumber,
                preference: preference,
                transportationMode: transportationMode,
                parkingSpot: parkingSpot,
                foodOrder: foodOrder
            )
        }

        // Real API implementation below
        let scheduleId = UUID().uuidString
        let targetArrivalTime = game.kickoffTime.addingTimeInterval(-Double(preference.minutesBeforeKickoff * 60))

        // 1. Get stadium crowd forecast
        let crowdForecast = await crowdService.getStadiumCrowdForecast(
            for: game.stadium,
            at: game.kickoffTime
        )

        // 2. Select best entry gate based on section number and crowd levels
        let gateRecommendation = gateService.recommendGate(
            for: sectionNumber,
            at: game.stadium,
            crowdForecast: crowdForecast
        )
        let recommendedGate = gateRecommendation.gate

        // 3. Calculate optimal departure time (work backwards from target arrival)
        let estimatedTravelTime = try await calculateOptimalTravelTime(
            from: userLocation,
            to: game.stadium,
            arrivalTime: targetArrivalTime
        )

        let departureTime = targetArrivalTime.addingTimeInterval(-Double(estimatedTravelTime * 60))

        // 4. Get the best route with traffic data
        let bestRoute = try await getBestRoute(
            from: userLocation,
            to: game.stadium,
            departureTime: departureTime
        )

        // 5. Create parking reservation if driving
        var parkingReservation: ParkingReservation?
        if transportationMode.requiresParking, let spot = parkingSpot {
            parkingReservation = try await createParkingReservation(
                spot: spot,
                startTime: departureTime,
                endTime: game.kickoffTime.addingTimeInterval(10800) // 3 hours after kickoff
            )
        }

        // 6. Generate schedule steps
        let steps = createScheduleSteps(
            game: game,
            userLocation: userLocation,
            targetArrival: targetArrivalTime,
            route: bestRoute,
            gate: recommendedGate,
            preference: preference,
            crowdForecast: crowdForecast,
            transportationMode: transportationMode,
            parkingSpot: parkingSpot,
            foodOrder: foodOrder
        )

        // 7. Calculate confidence score
        let confidenceScore = calculateConfidenceScore(
            crowdForecast: crowdForecast,
            arrivalPreference: preference,
            gate: recommendedGate,
            route: bestRoute
        )

        return GameSchedule(
            id: scheduleId,
            game: game,
            userLocation: userLocation,
            sectionNumber: sectionNumber,
            scheduleSteps: steps,
            recommendedGate: recommendedGate,
            purchaseDate: Date(),
            arrivalPreference: preference,
            transportationMode: transportationMode,
            parkingReservation: parkingReservation,
            foodOrder: foodOrder,
            confidenceScore: confidenceScore
        )
    }
    
    // MARK: - Private Helpers

    /// Calculate optimal travel time using Google Directions API with traffic data
    private func calculateOptimalTravelTime(
        from userLocation: UserLocation,
        to stadium: Stadium,
        arrivalTime: Date
    ) async throws -> Int {
        // Calculate departure time (work backwards)
        let departureTime = arrivalTime.addingTimeInterval(-60 * 60) // Start with 1 hour estimate

        let route = try await directionsService.getRoute(
            from: userLocation.coordinate.clLocation,
            to: stadium.coordinate.clLocation,
            departureTime: departureTime,
            travelMode: .transit
        )

        // Add buffer for crowds and safety margin
        return route.travelTimeMinutes + GoogleMapsConfig.crowdBufferMinutes
    }

    /// Get the best route considering both speed and crowd levels
    private func getBestRoute(
        from userLocation: UserLocation,
        to stadium: Stadium,
        departureTime: Date
    ) async throws -> RouteInfo {
        // Get multiple route options
        let routes = try await directionsService.getAlternativeRoutes(
            from: userLocation.coordinate.clLocation,
            to: stadium.coordinate.clLocation,
            departureTime: departureTime,
            travelMode: .transit
        )

        // Score routes based on time and crowd levels
        let scoredRoutes = await crowdService.scoreAndRankRoutes(
            routes,
            departureTime: departureTime
        )

        // Return best route (lowest score)
        guard let bestRoute = scoredRoutes.first else {
            throw ScheduleGenerationError.noRoutesAvailable
        }

        return bestRoute.route
    }
    
    private func createScheduleSteps(
        game: SportingEvent,
        userLocation: UserLocation,
        targetArrival: Date,
        route: RouteInfo,
        gate: EntryGate,
        preference: ArrivalPreference,
        crowdForecast: StadiumCrowdForecast,
        transportationMode: TransportationMode = .publicTransit,
        parkingSpot: ParkingSpot? = nil,
        foodOrder: FoodOrder? = nil
    ) -> [ScheduleStep] {
        let travelTime = route.travelTimeMinutes
        var steps: [ScheduleStep] = []

        // Work backwards from target arrival
        
        // Step 7: Settle in and enjoy (30 min before kickoff)
        let settleTime = game.kickoffTime.addingTimeInterval(-30 * 60)
        steps.append(ScheduleStep(
            id: UUID().uuidString,
            scheduledTime: settleTime,
            title: "Settle In & Enjoy",
            description: "You're here! Relax, soak in the atmosphere, and get ready for kickoff.",
            icon: "checkmark.seal.fill",
            estimatedDuration: 30,
            stepType: .milestone
        ))
        
        // Step 6: Find your seat (15 min before settle time)
        let seatTime = settleTime.addingTimeInterval(-15 * 60)
        steps.append(ScheduleStep(
            id: UUID().uuidString,
            scheduledTime: seatTime,
            title: "Find Your Seat",
            description: "Head to your section. Take your time, no rush.",
            icon: "mappin.and.ellipse",
            estimatedDuration: 15,
            stepType: .seating
        ))
        
        // Step 5: Food pickup or optional food time
        let foodTime: Date
        if let foodOrder = foodOrder {
            // Use the pre-ordered pickup time
            foodTime = foodOrder.pickupTime
            steps.append(ScheduleStep(
                id: UUID().uuidString,
                scheduledTime: foodTime,
                title: "Pick Up Pre-Ordered Food",
                description: "Pick up your order at \(foodOrder.vendorLocation). Confirmation: \(foodOrder.confirmationCode)",
                icon: "takeoutbag.and.cup.and.straw.fill",
                estimatedDuration: 5,
                stepType: .foodPickup
            ))
        } else {
            // Generic optional food time (20 min before seat time)
            foodTime = seatTime.addingTimeInterval(-20 * 60)
            steps.append(ScheduleStep(
                id: UUID().uuidString,
                scheduledTime: foodTime,
                title: "Grab Food & Drinks",
                description: "Optional: Get refreshments before heading to your seat.",
                icon: "cup.and.saucer.fill",
                estimatedDuration: 20,
                stepType: .milestone
            ))
        }
        
        // Step 4: Enter stadium (10 min before food time)
        let entryTime = foodTime.addingTimeInterval(-10 * 60)
        steps.append(ScheduleStep(
            id: UUID().uuidString,
            scheduledTime: entryTime,
            title: "Enter Stadium",
            description: "Go through security at \(gate.name). Have your ticket ready.",
            icon: "ticket.fill",
            estimatedDuration: 10,
            stepType: .entry
        ))
        
        // If driving, add parking and walk steps
        var transitStart: Date
        if transportationMode.requiresParking, let parking = parkingSpot {
            // Arrive at stadium gate (after walking from parking)
            let arrivalTime = entryTime.addingTimeInterval(-5 * 60)
            steps.append(ScheduleStep(
                id: UUID().uuidString,
                scheduledTime: arrivalTime,
                title: "Arrive at \(gate.name)",
                description: "Walk to the recommended entry gate. Crowd level: \(gate.currentCrowdLevel.rawValue)",
                icon: "building.2.fill",
                estimatedDuration: 5,
                stepType: .arrival
            ))

            // Walk from parking to stadium
            let walkStart = arrivalTime.addingTimeInterval(-Double(parking.walkingTimeToStadium * 60))
            steps.append(ScheduleStep(
                id: UUID().uuidString,
                scheduledTime: walkStart,
                title: "Walk to Stadium",
                description: "\(parking.walkingTimeToStadium) min walk from \(parking.name)",
                icon: "figure.walk",
                estimatedDuration: parking.walkingTimeToStadium,
                stepType: .transit
            ))

            // Park vehicle
            let parkTime = walkStart.addingTimeInterval(-10 * 60)
            steps.append(ScheduleStep(
                id: UUID().uuidString,
                scheduledTime: parkTime,
                title: "Park at \(parking.name)",
                description: "Reserved spot at \(parking.address). Confirmation: Show ParkMobile app.",
                icon: "parkingsign.circle.fill",
                estimatedDuration: 10,
                stepType: .parking
            ))

            // Drive to parking
            transitStart = parkTime.addingTimeInterval(-Double(travelTime * 60))
            let trafficDelay = route.trafficDelayMinutes
            let trafficNote = trafficDelay > 5 ? " (⚠️ +\(trafficDelay) min traffic delay)" : ""

            steps.append(ScheduleStep(
                id: UUID().uuidString,
                scheduledTime: transitStart,
                title: "Drive to Parking",
                description: "Follow Google Maps to \(parking.name). Drive time: \(travelTime) min\(trafficNote)",
                icon: "car.fill",
                estimatedDuration: travelTime,
                stepType: .transit
            ))
        } else {
            // Public transit or other modes
            let arrivalTime = entryTime.addingTimeInterval(-5 * 60)
            steps.append(ScheduleStep(
                id: UUID().uuidString,
                scheduledTime: arrivalTime,
                title: "Arrive at \(gate.name)",
                description: "Walk to the recommended entry gate. Crowd level: \(gate.currentCrowdLevel.rawValue)",
                icon: "building.2.fill",
                estimatedDuration: 5,
                stepType: .arrival
            ))

            transitStart = arrivalTime.addingTimeInterval(-Double(travelTime * 60))
            let trafficDelay = route.trafficDelayMinutes
            let trafficNote = trafficDelay > 5 ? " (⚠️ +\(trafficDelay) min traffic delay)" : ""

            let transitTitle: String
            let transitIcon: String
            switch transportationMode {
            case .driving:
                transitTitle = "Drive to Stadium"
                transitIcon = "car.fill"
            case .publicTransit:
                transitTitle = "Take Metro/Transit"
                transitIcon = "tram.fill"
            case .rideshare:
                transitTitle = "Take Rideshare"
                transitIcon = "car.circle.fill"
            case .walking:
                transitTitle = "Walk to Stadium"
                transitIcon = "figure.walk"
            }

            steps.append(ScheduleStep(
                id: UUID().uuidString,
                scheduledTime: transitStart,
                title: transitTitle,
                description: "Follow Google Maps route. Travel time: \(travelTime) min\(trafficNote). Crowd level: \(crowdForecast.emoji)",
                icon: transitIcon,
                estimatedDuration: travelTime,
                stepType: .transit
            ))
        }
        
        // Step 1: Leave hotel (5 min before transit)
        let departureTime = transitStart.addingTimeInterval(-5 * 60)
        steps.append(ScheduleStep(
            id: UUID().uuidString,
            scheduledTime: departureTime,
            title: "Leave \(userLocation.name)",
            description: "Time to go! Grab your tickets, ID, and essentials.",
            icon: "figure.walk.departure",
            estimatedDuration: 5,
            stepType: .departure
        ))
        
        // Sort steps chronologically
        return steps.sorted { $0.scheduledTime < $1.scheduledTime }
    }
    
    /// Create a parking reservation through ParkMobile
    private func createParkingReservation(
        spot: ParkingSpot,
        startTime: Date,
        endTime: Date
    ) async throws -> ParkingReservation {
        let parkingService = ParkMobileService.shared

        let bookingRequest = ParkingBookingRequest(
            spotId: spot.id,
            startTime: startTime,
            endTime: endTime,
            vehicleInfo: nil,
            paymentMethodId: "pm_mock_payment" // In production, this would come from user's payment method
        )

        return try await parkingService.createReservation(request: bookingRequest)
    }

    /// Update crowd levels for gates (now uses real crowd intelligence service)
    func updateCrowdLevels(for stadium: Stadium) async {
        // Now uses CrowdIntelligenceService for real-time updates
        let _ = await crowdService.getStadiumCrowdForecast(
            for: stadium,
            at: Date()
        )
        // Crowd levels are updated in the forecast
    }

    /// Calculate confidence score (0-100) for on-time arrival
    /// Higher score = higher confidence of arriving on time
    private func calculateConfidenceScore(
        crowdForecast: StadiumCrowdForecast,
        arrivalPreference: ArrivalPreference,
        gate: EntryGate,
        route: RouteInfo
    ) -> Int {
        var score = 100

        // Factor 1: Crowd level at gate (-30 to 0)
        switch gate.currentCrowdLevel {
        case .clear:
            score -= 0 // Perfect
        case .moderate:
            score -= 10
        case .crowded:
            score -= 20
        case .avoid:
            score -= 30
        }

        // Factor 2: Overall stadium crowd intensity (-20 to 0)
        switch crowdForecast.overallCrowdIntensity {
        case .low:
            score -= 0
        case .moderate:
            score -= 5
        case .high:
            score -= 10
        case .veryHigh:
            score -= 15
        case .extreme:
            score -= 20
        }

        // Factor 3: Traffic delay on route (-15 to 0)
        let trafficDelay = route.trafficDelayMinutes
        if trafficDelay > 20 {
            score -= 15
        } else if trafficDelay > 10 {
            score -= 10
        } else if trafficDelay > 5 {
            score -= 5
        }

        // Factor 4: Time buffer from arrival preference (+5 to +15 bonus)
        switch arrivalPreference {
        case .relaxed:
            score += 15 // Lots of buffer
        case .balanced:
            score += 10 // Good buffer
        case .efficient:
            score += 5  // Minimal buffer
        }

        // Ensure score is in valid range
        return max(60, min(100, score)) // Never below 60%, never above 100%
    }
}

// MARK: - Errors

enum ScheduleGenerationError: LocalizedError {
    case noRoutesAvailable
    case geocodingFailed
    case directionsFailed

    var errorDescription: String? {
        switch self {
        case .noRoutesAvailable:
            return "No routes available to the stadium. Please check your location."
        case .geocodingFailed:
            return "Could not find your address. Please try again."
        case .directionsFailed:
            return "Could not calculate directions. Please check your internet connection."
        }
    }
}
