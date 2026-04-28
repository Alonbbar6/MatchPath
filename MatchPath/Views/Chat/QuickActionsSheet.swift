import SwiftUI

/// Smart Action Buttons - Instant answers to common questions
/// Replaces typing with context-aware action buttons for faster UX
struct QuickActionsSheet: View {
    let schedule: GameSchedule
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAction: QuickAction?
    @State private var showingActionDetail = false
    @State private var showingAIChatbot = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)

                        Text("How can we help?")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Tap any question for instant answers")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)

                    // Emergency Actions (Red - High priority)
                    ActionCategoryCard(
                        title: "Need Help Now?",
                        icon: "exclamationmark.triangle.fill",
                        color: .red,
                        actions: emergencyActions
                    ) { action in
                        selectedAction = action
                        showingActionDetail = true
                    }

                    // Common Questions (Blue - Most used)
                    ActionCategoryCard(
                        title: "Common Questions",
                        icon: "questionmark.circle.fill",
                        color: .blue,
                        actions: commonQuestions
                    ) { action in
                        selectedAction = action
                        showingActionDetail = true
                    }

                    // Stadium Info (Orange - Location-based)
                    ActionCategoryCard(
                        title: "Stadium & Amenities",
                        icon: "building.2.fill",
                        color: .orange,
                        actions: stadiumInfoActions
                    ) { action in
                        selectedAction = action
                        showingActionDetail = true
                    }

                    // Gate & Entry (Green)
                    ActionCategoryCard(
                        title: "Entry & Security",
                        icon: "door.left.hand.open",
                        color: .green,
                        actions: gateInfoActions
                    ) { action in
                        selectedAction = action
                        showingActionDetail = true
                    }

                    Divider()
                        .padding(.vertical)

                    // Still need help? Link to AI chat
                    Button {
                        showingAIChatbot = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "sparkles")
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Still need help?")
                                    .font(.headline)
                                Text("Ask our AI assistant anything")
                                    .font(.caption)
                            }
                            Spacer()
                            Image(systemName: "arrow.right")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Quick Help")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #else
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #endif
            }
            .sheet(isPresented: $showingActionDetail) {
                if let action = selectedAction {
                    ActionDetailView(action: action, schedule: schedule)
                }
            }
            .sheet(isPresented: $showingAIChatbot) {
                ChatbotView(schedule: schedule)
            }
        }
    }

    // MARK: - Action Categories

    private var emergencyActions: [QuickAction] {
        [
            QuickAction(
                id: "running-late",
                title: "I'm Running Late",
                icon: "clock.badge.exclamationmark",
                category: .emergency,
                answer: generateRunningLateAnswer()
            ),
            QuickAction(
                id: "lost",
                title: "I'm Lost / Can't Find My Gate",
                icon: "map.fill",
                category: .emergency,
                answer: generateLostAnswer()
            ),
            QuickAction(
                id: "gate-closed",
                title: "My Gate is Closed",
                icon: "xmark.circle",
                category: .emergency,
                answer: generateGateClosedAnswer()
            ),
            QuickAction(
                id: "medical",
                title: "Medical Emergency",
                icon: "cross.case.fill",
                category: .emergency,
                answer: "Call 911 or find the nearest First Aid station:\n\n" +
                "📍 First Aid Locations:\n" +
                "• Main Concourse (near Gate A)\n" +
                "• Upper Level (Section 200)\n" +
                "• Field Level (near Gate D)\n\n" +
                "🚨 Stadium medical staff are located at all major gates.\n\n" +
                "Emergency: 911\nStadium Security: Text 69050"
            )
        ]
    }

    private var commonQuestions: [QuickAction] {
        [
            QuickAction(
                id: "bathroom",
                title: "Where's the Nearest Bathroom?",
                icon: "figure.walk",
                category: .common,
                answer: generateBathroomAnswer()
            ),
            QuickAction(
                id: "food",
                title: "Where Can I Get Food?",
                icon: "fork.knife",
                category: .common,
                answer: generateFoodAnswer()
            ),
            QuickAction(
                id: "wifi",
                title: "WiFi Password",
                icon: "wifi",
                category: .common,
                answer: "📶 Free Stadium WiFi:\n\n" +
                "Network: Stadium_Guest\n" +
                "Password: GameDay2026\n\n" +
                "No login required. Connect and enjoy!\n\n" +
                "💡 Tip: Connect when you first arrive for the best experience."
            ),
            QuickAction(
                id: "reentry",
                title: "Can I Re-Enter the Stadium?",
                icon: "arrow.uturn.left.circle",
                category: .common,
                answer: "⚠️ Re-Entry Policy:\n\n" +
                "❌ No re-entry allowed once you exit the stadium.\n\n" +
                "Make sure you have everything you need before entering:\n" +
                "• Phone charged\n" +
                "• Tickets ready\n" +
                "• Any medications\n\n" +
                "💡 Tip: There are phone charging stations inside."
            ),
            QuickAction(
                id: "parking",
                title: "Where Did I Park?",
                icon: "car.fill",
                category: .common,
                answer: generateParkingAnswer()
            ),
            QuickAction(
                id: "lost-item",
                title: "I Lost Something",
                icon: "questionmark.square",
                category: .common,
                answer: "Lost & Found:\n\n" +
                "📍 Location: Guest Services (Main Entrance)\n" +
                "📞 Phone: (555) 123-4567\n" +
                "📧 Email: lostandfound@stadium.com\n\n" +
                "Items are held for 30 days.\n\n" +
                "💡 Tip: Check with the nearest stadium staff immediately."
            )
        ]
    }

    private var stadiumInfoActions: [QuickAction] {
        [
            QuickAction(
                id: "my-seat",
                title: "Where's My Seat?",
                icon: "chair.fill",
                category: .stadium,
                answer: generateSeatAnswer()
            ),
            QuickAction(
                id: "amenities",
                title: "What Amenities Are Near Me?",
                icon: "map.circle.fill",
                category: .stadium,
                answer: generateAmenitiesAnswer()
            ),
            QuickAction(
                id: "atm",
                title: "Where's the ATM?",
                icon: "dollarsign.circle",
                category: .stadium,
                answer: "🏧 ATM Locations:\n\n" +
                "• Main Concourse (near Gate A)\n" +
                "• Upper Level (Section 200 entrance)\n" +
                "• Club Level (near elevators)\n\n" +
                "💳 Most vendors accept credit/debit cards and mobile payments."
            ),
            QuickAction(
                id: "smoking",
                title: "Smoking Area",
                icon: "smoke.fill",
                category: .stadium,
                answer: "🚬 Smoking Policy:\n\n" +
                "❌ Smoking is prohibited inside the stadium.\n\n" +
                "Designated smoking areas are located outside:\n" +
                "• North Plaza (near Gate A)\n" +
                "• South Plaza (near Gate D)\n\n" +
                "⚠️ Remember: No re-entry allowed."
            )
        ]
    }

    private var gateInfoActions: [QuickAction] {
        [
            QuickAction(
                id: "recommended-gate",
                title: "Which Gate Should I Use?",
                icon: "door.left.hand.open",
                category: .gate,
                answer: generateRecommendedGateAnswer()
            ),
            QuickAction(
                id: "prohibited-items",
                title: "What Can't I Bring?",
                icon: "xmark.shield",
                category: .gate,
                answer: "🚫 Prohibited Items:\n\n" +
                "❌ Bags larger than 12\"x12\"x6\"\n" +
                "❌ Weapons of any kind\n" +
                "❌ Outside food & beverages\n" +
                "❌ Professional cameras\n" +
                "❌ Selfie sticks & tripods\n" +
                "❌ Drones\n" +
                "❌ Laser pointers\n" +
                "❌ Fireworks\n\n" +
                "✅ Small purses, phones, and small cameras are OK."
            ),
            QuickAction(
                id: "security-wait",
                title: "How Long is Security Wait?",
                icon: "clock.arrow.circlepath",
                category: .gate,
                answer: generateSecurityWaitAnswer()
            ),
            QuickAction(
                id: "accessibility",
                title: "Accessibility Services",
                icon: "figure.roll",
                category: .gate,
                answer: "♿️ Accessibility Services:\n\n" +
                "• Wheelchair accessible entrances at all gates\n" +
                "• Elevators available to all levels\n" +
                "• Accessible seating sections available\n" +
                "• Companion seating provided\n" +
                "• Accessible restrooms on all levels\n\n" +
                "📞 Guest Services: (555) 123-4567\n\n" +
                "💡 Use Gate B for fastest wheelchair access."
            )
        ]
    }

    // MARK: - Context-Aware Answer Generation

    private func generateRunningLateAnswer() -> String {
        let kickoff = schedule.game.kickoffTime
        let gateOpen = Calendar.current.date(byAdding: .hour, value: -2, to: kickoff) ?? kickoff
        let recommendedGate = schedule.recommendedGate.name

        return """
        ⚠️ Running Late? Here's what to do:

        🚀 FASTEST ROUTE:
        • Use \(recommendedGate) (least crowded)
        • Skip food/bathroom until you're seated
        • Have your ticket ready BEFORE security

        ⏰ TIME CHECK:
        • Gates open: \(formatTime(gateOpen))
        • Kickoff: \(formatTime(kickoff))
        • Your gate: \(recommendedGate)

        💡 PRO TIPS:
        • Security is fastest 60-90 min before kickoff
        • If you arrive late, gates may have longer lines
        • Download your ticket now to save time

        You've got this! 💪
        """
    }

    private func generateLostAnswer() -> String {
        let recommendedGate = schedule.recommendedGate.name
        let stadium = schedule.game.stadium.name

        return """
        📍 Finding Your Way:

        YOUR RECOMMENDED GATE: \(recommendedGate)

        🗺️ FROM PARKING/METRO:
        1. Look for "\(stadium)" signs
        2. Follow the crowd toward the stadium
        3. Look for "\(recommendedGate)" signs

        📱 NEED DIRECTIONS?
        • Tap "Indoor Compass (AR)" button to use AR navigation
        • Tap "Stadium Map" to see your location

        🙋 ASK FOR HELP:
        • Stadium staff wear yellow vests
        • Security can direct you to your gate

        Don't worry - you're not lost, you're on an adventure! 🎯
        """
    }

    private func generateGateClosedAnswer() -> String {
        let recommendedGate = schedule.recommendedGate.name
        let allGates = schedule.game.stadium.entryGates.map { $0.name }.joined(separator: ", ")

        return """
        🚪 Gate Closed? Try These:

        YOUR RECOMMENDED GATE: \(recommendedGate)

        ✅ ALTERNATIVE GATES:
        All these gates can access your section:
        \(allGates)

        💡 QUICK FIX:
        1. Find the nearest open gate
        2. Show your ticket to staff
        3. They'll direct you to the right entrance

        ⏰ NOTE:
        • Gates close 15 minutes before kickoff
        • Late arrivals use designated late-entry gates

        📍 STAFF ASSISTANCE:
        Ask any yellow-vested staff member for help finding an open gate.
        """
    }

    private func generateBathroomAnswer() -> String {
        guard let section = schedule.sectionNumber else {
            return """
            🚻 Restroom Locations:

            Restrooms are located:
            • On every level of the stadium
            • Near all major entry gates
            • Behind most seating sections

            💡 Look for the universal restroom signs, or ask any staff member.
            """
        }

        return """
        🚻 Nearest Restrooms to Section \(section):

        CLOSEST OPTIONS:
        • Behind Section \(section) (main concourse)
        • Near your entry gate: \(schedule.recommendedGate.name)
        • Family restroom available on main level

        💡 PRO TIP:
        Restrooms are less crowded:
        • 30 minutes before kickoff
        • During halftime (but expect lines)

        🚶 Most restrooms are within 1 minute walk from your seat.
        """
    }

    private func generateFoodAnswer() -> String {
        guard let section = schedule.sectionNumber else {
            return """
            🍔 Food & Beverage:

            Food vendors are located:
            • On every concourse level
            • Near all major gates
            • Throughout the stadium

            💳 Payment: Credit/debit cards and mobile payments accepted.
            """
        }

        return """
        🍔 Food Near Section \(section):

        CLOSEST VENDORS:
        • Hot dogs & burgers (behind Section \(section))
        • Pizza & pasta (near \(schedule.recommendedGate.name))
        • Drinks & snacks (multiple locations)

        💡 ORDERING TIPS:
        • Mobile order available via stadium app
        • Lines are shortest right after kickoff
        • Last call: 75th minute

        💳 All vendors accept cards and mobile payments.

        📱 Pro Tip: Pre-order on the stadium app to skip lines!
        """
    }

    private func generateParkingAnswer() -> String {
        if let parking = schedule.parkingReservation {
            return """
            🚗 Your Parking Info:

            LOT: \(parking.parkingSpot.name)
            ADDRESS: \(parking.parkingSpot.address)

            📍 TO FIND YOUR CAR AFTER THE GAME:
            • Look for lot signs showing "\(parking.parkingSpot.name)"
            • Take a photo of your parking spot now
            • Note nearby landmarks

            💡 LEAVING THE STADIUM:
            Exit via \(schedule.recommendedGate.name) and follow signs to \(parking.parkingSpot.name).

            ⏱️ Expect 20-30 min to exit parking after the game.
            """
        } else {
            return """
            🚗 Finding Your Parking:

            💡 TIPS TO REMEMBER:
            • Take a photo of your lot/spot number NOW
            • Note the lot name/color
            • Save a pin in your maps app

            📱 USE YOUR PHONE:
            • Open Maps and drop a pin at your car
            • Take a photo of your parking spot

            🚶 AFTER THE GAME:
            Follow signs to your parking lot. Stadium staff can help direct you.
            """
        }
    }

    private func generateSeatAnswer() -> String {
        guard let section = schedule.sectionNumber else {
            return """
            💺 Finding Your Seat:

            1. Enter through your assigned gate
            2. Look for your section number on signs
            3. Find an usher in a yellow vest
            4. Show them your ticket

            They'll point you in the right direction!
            """
        }

        return """
        💺 Finding Section \(section):

        🚪 ENTRY:
        Use \(schedule.recommendedGate.name) - it's closest to your section

        🗺️ DIRECTIONS:
        1. Enter through \(schedule.recommendedGate.name)
        2. Look for "Section \(section)" signs
        3. Head to the concourse level
        4. Ushers will guide you to your row

        💡 PRO TIP:
        Tap "Stadium Map & Amenities" button to see your section on the interactive map.

        🎯 You're in a great spot for the game!
        """
    }

    private func generateAmenitiesAnswer() -> String {
        guard let section = schedule.sectionNumber else {
            return """
            🏟️ Stadium Amenities:

            Available on all levels:
            • Restrooms
            • Food & beverage vendors
            • First aid stations
            • Guest services
            • ATMs
            • Phone charging stations

            Tap "Stadium Map" for exact locations!
            """
        }

        return """
        🏟️ Amenities Near Section \(section):

        WITHIN 1 MINUTE WALK:
        🚻 Restrooms - Behind your section
        🍔 Food Court - Main concourse
        📱 Phone Charging - Near \(schedule.recommendedGate.name)

        WITHIN 2 MINUTES:
        🏧 ATM - Main level
        🏥 First Aid - Near Gate entrance
        👕 Team Store - Main concourse

        💡 Use the "Stadium Map & Amenities" button to see exact locations with turn-by-turn directions!
        """
    }

    private func generateRecommendedGateAnswer() -> String {
        let gate = schedule.recommendedGate
        let crowdLevel = gate.currentCrowdLevel.rawValue

        return """
        🚪 Your Recommended Gate: \(gate.name)

        WHY THIS GATE?
        ✅ Closest to your section
        ✅ Current crowd level: \(crowdLevel)
        ✅ Fastest entry based on your arrival time

        📍 LOCATION:
        Look for "\(gate.name)" signs around the stadium perimeter

        ⏰ TIMING:
        Best time to arrive: 90 minutes before kickoff

        💡 PRO TIP:
        Have your ticket QR code ready on your phone BEFORE you reach security to speed things up!

        Alternative gates: You can use any gate, but this one is optimized for you.
        """
    }

    private func generateSecurityWaitAnswer() -> String {
        let gate = schedule.recommendedGate
        let crowdLevel = gate.currentCrowdLevel

        let waitTime: String
        let waitColor: String

        switch crowdLevel {
        case .clear:
            waitTime = "0-5 minutes"
            waitColor = "🟢"
        case .moderate:
            waitTime = "5-15 minutes"
            waitColor = "🟡"
        case .crowded:
            waitTime = "15-30 minutes"
            waitColor = "🟠"
        case .avoid:
            waitTime = "30+ minutes"
            waitColor = "🔴"
        }

        return """
        ⏱️ Security Wait Times:

        YOUR GATE (\(gate.name)):
        \(waitColor) Current wait: ~\(waitTime)

        💡 FASTEST ENTRY TIMES:
        • 90-120 minutes before kickoff (shortest lines)
        • 30 minutes before kickoff (moderate)
        • At kickoff (longest lines)

        🚀 SPEED UP SECURITY:
        ✅ Have ticket ready on phone
        ✅ Empty pockets before security
        ✅ Small bag or no bag
        ✅ Know what's prohibited

        📊 Live crowd data updates every 5 minutes.
        """
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views

struct ActionCategoryCard: View {
    let title: String
    let icon: String
    let color: Color
    let actions: [QuickAction]
    let onActionTap: (QuickAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Category Header
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Text(title)
                    .font(.headline)

                Spacer()
            }

            // Action Buttons
            VStack(spacing: 12) {
                ForEach(actions) { action in
                    Button {
                        onActionTap(action)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: action.icon)
                                .font(.title3)
                                .foregroundColor(color)
                                .frame(width: 32)

                            Text(action.title)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(red: 0.949, green: 0.949, blue: 0.969))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct ActionDetailView: View {
    let action: QuickAction
    let schedule: GameSchedule
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: action.icon)
                            .font(.system(size: 60))
                            .foregroundColor(categoryColor(action.category))

                        Text(action.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)

                    // Answer
                    Text(action.answer)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)

                    Divider()

                    // Helpful Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Helpful Actions:")
                            .font(.headline)

                        if action.id == "my-seat" || action.id == "amenities" {
                            Button {
                                // TODO: Open stadium map
                                dismiss()
                            } label: {
                                ActionButtonRow(
                                    icon: "map.circle.fill",
                                    title: "Open Stadium Map",
                                    color: .orange
                                )
                            }
                        }

                        if action.id == "lost" {
                            HStack {
                                Image(systemName: "safari")
                                    .foregroundColor(.gray)
                                Text("AR Compass")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("Coming Soon")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.gray.opacity(0.2))
                                    .foregroundColor(.secondary)
                                    .cornerRadius(8)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }

                        if action.id == "running-late" {
                            Button {
                                // TODO: Show live tracking
                                dismiss()
                            } label: {
                                ActionButtonRow(
                                    icon: "map.fill",
                                    title: "Track on Map",
                                    color: .green
                                )
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Quick Help")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #else
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #endif
            }
        }
    }

    private func categoryColor(_ category: ActionCategory) -> Color {
        switch category {
        case .emergency: return .red
        case .common: return .blue
        case .stadium: return .orange
        case .gate: return .green
        }
    }
}

struct ActionButtonRow: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(title)
                .foregroundColor(.primary)
            Spacer()
            Image(systemName: "arrow.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(red: 0.949, green: 0.949, blue: 0.969))
        .cornerRadius(12)
    }
}

// MARK: - Data Models

struct QuickAction: Identifiable {
    let id: String
    let title: String
    let icon: String
    let category: ActionCategory
    let answer: String
}

enum ActionCategory {
    case emergency
    case common
    case stadium
    case gate
}

#Preview {
    let mockGame = SportingEvent.sampleEvents[0]
    let mockLocation = UserLocation(
        name: "Marriott Hotel",
        address: "123 Main St, Miami, FL",
        coordinate: Coordinate(latitude: 25.7617, longitude: -80.1918)
    )

    let mockSchedule = GameSchedule(
        id: "preview-schedule",
        game: mockGame,
        userLocation: mockLocation,
        sectionNumber: "118",
        scheduleSteps: [],
        recommendedGate: mockGame.stadium.entryGates[0],
        purchaseDate: Date(),
        arrivalPreference: .balanced,
        transportationMode: .publicTransit,
        parkingReservation: nil,
        foodOrder: nil,
        confidenceScore: 92
    )

    QuickActionsSheet(schedule: mockSchedule)
}
