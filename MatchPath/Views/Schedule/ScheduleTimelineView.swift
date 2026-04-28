import SwiftUI

struct ScheduleTimelineView: View {
    let schedule: GameSchedule
    @Environment(\.dismiss) private var dismiss
    @StateObject private var crowdUpdateService = CrowdUpdateService.shared
    @StateObject private var persistenceService = SchedulePersistenceService.shared
    @StateObject private var premiumManager = PremiumManager.shared
    @State private var showingCelebration = false
    @State private var showingMap = false
    @State private var showingNavigationPicker = false
    @State private var isRefreshing = false
    @State private var showingChatbot = false
    @State private var showingQuickActions = false
    @State private var showingIndoorCompass = false
    @State private var showingIndoorStadiumMap = false
    @State private var showingSaveConfirmation = false
    @State private var showingPremiumPaywall = false
    @State private var isSaved = false
    
    var body: some View {
        NavigationStack {
            content
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
                    ToolbarItem(placement: .automatic) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                    #endif
                }
                .onAppear {
                    showingCelebration = true
                    // Start real-time crowd updates
                    crowdUpdateService.startUpdates(for: schedule)
                }
                .onDisappear {
                    // Stop updates when view disappears
                    crowdUpdateService.stopUpdates()
                }
        }
    }
    
    // Extract main content to reduce complexity in body
    private var content: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: 24) {
                    // Success Header
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                            .scaleEffect(showingCelebration ? 1.2 : 1.0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showingCelebration)
                        
                        Text("Your Schedule is Ready!")
                            .font(.system(.title, design: .rounded))
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("Follow these steps for a stress-free game day")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Game Info Card
                    GameInfoCard(game: schedule.game)
                    
                    // Timeline
                    VStack(alignment: .leading, spacing: 0) {
                        // Use indices to avoid enumerated() id pitfalls
                        ForEach(schedule.scheduleSteps.indices, id: \.self) { index in
                            let step = schedule.scheduleSteps[index]
                            TimelineStepView(
                                step: step,
                                isFirst: index == 0,
                                isLast: index == schedule.scheduleSteps.count - 1
                            )
                        }
                    }
                    
                    // Key Info Card
                    KeyInfoCard(schedule: schedule)

                    // Confidence Guarantee Card
                    ConfidenceGuaranteeCard(schedule: schedule)

                    // Live Crowd Updates Card
                    LiveCrowdUpdatesCard(
                        schedule: schedule,
                        crowdUpdateService: crowdUpdateService,
                        isRefreshing: $isRefreshing
                    )

                    // Action Buttons
                    VStack(spacing: 12) {
                        // Start Navigation button (NEW!)
                        Button {
                            showingNavigationPicker = true
                        } label: {
                            HStack {
                                Image(systemName: "location.north.circle.fill")
                                Text("Start Navigation")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .tint(.green)

                        // Indoor Compass button (coming soon)
                        HStack {
                            Image(systemName: "safari")
                            Text("Indoor Compass (AR)")
                            Spacer()
                            Text("Coming Soon")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .opacity(0.5)
                        .allowsHitTesting(false)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3)))
                        .padding(.horizontal)

                        // Indoor Stadium Map button
                        Button {
                            showingIndoorStadiumMap = true
                        } label: {
                            HStack {
                                Image(systemName: "map.circle.fill")
                                Text("Stadium Map & Amenities")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .tint(.orange)

                        // Track on Map button
                        Button {
                            showingMap = true
                        } label: {
                            HStack {
                                Image(systemName: "map.fill")
                                Text("Track on Map")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)

                        Button {
                            saveScheduleAndNotifications()
                        } label: {
                            HStack {
                                Image(systemName: isSaved ? "checkmark.circle.fill" : "bell.badge.fill")
                                Text(isSaved ? "Schedule Saved!" : "Save & Enable Notifications")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(isSaved)
                        .alert("Schedule Saved!", isPresented: $showingSaveConfirmation) {
                            Button("View My Schedules") {
                                // Navigate to schedules list
                                dismiss()
                            }
                            Button("OK", role: .cancel) { }
                        } message: {
                            Text("Your schedule has been saved and notifications are enabled. We'll remind you at each step!")
                        }

                        Button {
                            // TODO: Share schedule
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share Schedule")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }
                    .padding(.top, 20)
                }
                .padding()
                .padding(.bottom, 80) // Add padding for floating chat button
            }

            // Floating Help Button (Quick Actions)
            Button {
                showingQuickActions = true
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)

                    VStack(spacing: 2) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)

                        Text("Help")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
        #if os(iOS)
        .fullScreenCover(isPresented: $showingMap) {
            NavigationView {
                ScheduleMapView(schedule: schedule)
            }
        }
        #else
        .sheet(isPresented: $showingMap) {
            NavigationView {
                ScheduleMapView(schedule: schedule)
            }
            .frame(minWidth: 800, minHeight: 600)
        }
        #endif
        .sheet(isPresented: $showingNavigationPicker) {
            NavigationAppPickerView(
                origin: schedule.userLocation.coordinate,
                destination: schedule.game.stadium.coordinate,
                destinationName: schedule.game.stadium.displayName
            )
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingQuickActions) {
            QuickActionsSheet(schedule: schedule)
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showingChatbot) {
            ChatbotView(schedule: schedule)
        }
        .sheet(isPresented: $showingPremiumPaywall) {
            SchedulePaywallView(game: nil, onPurchaseComplete: {
                // Refresh premium status after purchase
            })
        }
        #if os(iOS)
        .fullScreenCover(isPresented: $showingIndoorStadiumMap) {
            IndoorStadiumMapView(schedule: schedule, onIndoorCompass: { })
        }
        #else
        .sheet(isPresented: $showingIndoorStadiumMap) {
            IndoorStadiumMapView(schedule: schedule, onIndoorCompass: { })
                .frame(minWidth: 800, minHeight: 600)
        }
        #endif
    }

    // MARK: - Helper Methods

    /// Save schedule and enable notifications
    private func saveScheduleAndNotifications() {
        print("💾 Saving schedule...")

        // Save schedule using persistence service
        let success = persistenceService.saveSchedule(schedule)

        if success {
            print("✅ Schedule saved successfully!")

            // Enable notifications
            Task {
                await NotificationService.shared.scheduleNotifications(for: schedule)
                print("🔔 Notifications scheduled")

                await MainActor.run {
                    isSaved = true
                    showingSaveConfirmation = true
                }
            }
        } else {
            print("❌ Failed to save schedule")
            // TODO: Show error alert
        }
    }
}

// MARK: - Supporting Views

struct GameInfoCard: View {
    let game: SportingEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sportscourt.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(game.displayName)
                        .font(.headline)
                    
                    Text(game.matchday)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Kickoff", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(game.formattedKickoff)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Divider()
                    .frame(height: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Label("Stadium", systemImage: "building.2")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(game.stadium.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(
            // Use platform-appropriate background color init
            Group {
                #if os(iOS)
                Color(.systemBackground)
                #else
                Color(nsColor: .windowBackgroundColor)
                #endif
            }
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
    }
}

struct TimelineStepView: View {
    let step: ScheduleStep
    let isFirst: Bool
    let isLast: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Timeline indicator
            VStack(spacing: 0) {
                if !isFirst {
                    Rectangle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 2, height: 20)
                }
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: step.icon)
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    )
                
                if !isLast {
                    Rectangle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 2)
                        .frame(minHeight: 60)
                }
            }
            
            // Step content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(step.formattedTime)
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text(step.timeUntil)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Text(step.title)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text(step.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text("\(step.estimatedDuration) min")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, isLast ? 0 : 20)
        }
    }
}

struct KeyInfoCard: View {
    let schedule: GameSchedule
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Information")
                .font(.headline)
            
            VStack(spacing: 12) {
                ScheduleInfoRow(
                    icon: "mappin.circle.fill",
                    title: "Recommended Gate",
                    value: schedule.recommendedGate.name,
                    color: .green
                )
                
                ScheduleInfoRow(
                    icon: "person.3.fill",
                    title: "Crowd Level",
                    value: schedule.recommendedGate.currentCrowdLevel.rawValue,
                    color: crowdLevelColor(schedule.recommendedGate.currentCrowdLevel)
                )
                
                ScheduleInfoRow(
                    icon: "clock.fill",
                    title: "Total Journey Time",
                    value: "\(totalDuration(schedule)) min",
                    color: .blue
                )
            }
        }
        .padding()
        .background(
            Group {
                #if os(iOS)
                Color(.systemBackground)
                #else
                Color(nsColor: .windowBackgroundColor)
                #endif
            }
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
    }
    
    private func crowdLevelColor(_ level: CrowdLevel) -> Color {
        switch level {
        case .clear: return .green
        case .moderate: return .yellow
        case .crowded: return .orange
        case .avoid: return .red
        }
    }
    
    private func totalDuration(_ schedule: GameSchedule) -> Int {
        schedule.scheduleSteps.reduce(0) { $0 + $1.estimatedDuration }
    }
}

struct ScheduleInfoRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Live Crowd Updates Card

struct LiveCrowdUpdatesCard: View {
    let schedule: GameSchedule
    @ObservedObject var crowdUpdateService: CrowdUpdateService
    @Binding var isRefreshing: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with refresh button
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title3)
                        .foregroundColor(.blue)

                    Text("Live Crowd Updates")
                        .font(.headline)
                }

                Spacer()

                // Refresh button
                Button {
                    Task {
                        isRefreshing = true
                        await crowdUpdateService.manualRefresh(for: schedule)
                        // Add small delay so user sees the refresh
                        try? await Task.sleep(nanoseconds: 500_000_000)
                        isRefreshing = false
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                            .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                            .animation(isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)

                        if !isRefreshing {
                            Text("Refresh")
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                .disabled(isRefreshing)
            }

            // Update status indicator
            if crowdUpdateService.isUpdating {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)

                    Text("Live updates active")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    if let lastUpdate = crowdUpdateService.lastUpdateTime {
                        Text("Updated \(timeAgo(lastUpdate))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Current crowd data
            if let forecast = crowdUpdateService.currentForecast {
                VStack(spacing: 12) {
                    ScheduleInfoRow(
                        icon: "person.3.fill",
                        title: "Current Crowd Level",
                        value: forecast.overallUICrowdLevel.rawValue,
                        color: crowdLevelColor(forecast.overallUICrowdLevel)
                    )

                    ScheduleInfoRow(
                        icon: "clock.fill",
                        title: "Estimated Wait Time",
                        value: "\(forecast.estimatedWaitTimeMinutes) min",
                        color: waitTimeColor(forecast.estimatedWaitTimeMinutes)
                    )

                    if let bestGate = forecast.recommendedGates.first {
                        ScheduleInfoRow(
                            icon: "door.left.hand.open",
                            title: "Least Crowded Gate",
                            value: bestGate.name,
                            color: .green
                        )
                    }
                }
            } else {
                // Loading state
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading crowd data...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }

            // Next update indicator
            if crowdUpdateService.isUpdating && !isRefreshing {
                Text("Next update in \(crowdUpdateService.timeUntilNextUpdate)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            Group {
                #if os(iOS)
                Color(.systemBackground)
                #else
                Color(nsColor: .windowBackgroundColor)
                #endif
            }
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
    }

    private func crowdLevelColor(_ level: CrowdLevel) -> Color {
        switch level {
        case .clear: return .green
        case .moderate: return .yellow
        case .crowded: return .orange
        case .avoid: return .red
        }
    }

    private func waitTimeColor(_ minutes: Int) -> Color {
        switch minutes {
        case 0..<5: return .green
        case 5..<10: return .yellow
        case 10..<15: return .orange
        default: return .red
        }
    }

    private func timeAgo(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))

        if seconds < 60 {
            return "just now"
        } else if seconds < 120 {
            return "1 min ago"
        } else if seconds < 3600 {
            return "\(seconds / 60) min ago"
        } else {
            return "\(seconds / 3600) hr ago"
        }
    }
}

// MARK: - Confidence Guarantee Card

struct ConfidenceGuaranteeCard: View {
    let schedule: GameSchedule

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title3)
                    .foregroundColor(confidenceColor)

                Text("On-Time Confidence")
                    .font(.headline)
            }

            // Large confidence percentage
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(schedule.confidenceScore)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(confidenceColor)

                        Text("%")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(confidenceColor)
                    }

                    Text(schedule.confidenceDescription)
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Progress ring (simplified)
                ZStack {
                    Circle()
                        .stroke(lineWidth: 8)
                        .opacity(0.2)
                        .foregroundColor(confidenceColor)

                    Circle()
                        .trim(from: 0.0, to: CGFloat(schedule.confidenceScore) / 100.0)
                        .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
                        .foregroundColor(confidenceColor)
                        .rotationEffect(Angle(degrees: 270.0))

                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(confidenceColor)
                }
                .frame(width: 70, height: 70)
            }

            Divider()

            // What this means
            VStack(alignment: .leading, spacing: 8) {
                Text("What this means:")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(confidenceMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Factors
            if schedule.sectionNumber != nil {
                HStack(spacing: 4) {
                    Image(systemName: "info.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.blue)
                    Text("Optimized for your section (\(schedule.sectionNumber!))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            Group {
                #if os(iOS)
                Color(.systemBackground)
                #else
                Color(nsColor: .windowBackgroundColor)
                #endif
            }
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(confidenceColor.opacity(0.3), lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
    }

    private var confidenceColor: Color {
        switch schedule.confidenceScore {
        case 90...100:
            return .green
        case 80..<90:
            return .blue
        case 70..<80:
            return .yellow
        default:
            return .orange
        }
    }

    private var confidenceMessage: String {
        switch schedule.confidenceScore {
        case 90...100:
            return "Based on current conditions, you have an excellent chance of arriving comfortably before kickoff. Follow this schedule and you're guaranteed a stress-free experience."
        case 80..<90:
            return "You have a very good chance of arriving on time. Minor delays are accounted for in your schedule buffer."
        case 70..<80:
            return "Good chance of on-time arrival. Stay alert to any schedule updates and you'll be fine."
        default:
            return "Moderate confidence. Consider leaving earlier if possible, and monitor live crowd updates closely."
        }
    }
}

#Preview {
    let mockGame = SportingEvent.sampleEvents[0]
    let mockLocation = UserLocation(
        name: "Marriott Hotel",
        address: "123 Main St, Miami, FL",
        coordinate: Coordinate(latitude: 25.7617, longitude: -80.1918)
    )

    // Create a mock schedule directly for preview (avoiding async call in preview)
    let mockSchedule = GameSchedule(
        id: "preview-schedule",
        game: mockGame,
        userLocation: mockLocation,
        sectionNumber: "118",
        scheduleSteps: [
            ScheduleStep(
                id: "step-1",
                scheduledTime: Date().addingTimeInterval(-3600),
                title: "Leave Hotel",
                description: "Time to go! Grab your tickets and essentials.",
                icon: "figure.walk.departure",
                estimatedDuration: 5,
                stepType: .departure
            ),
            ScheduleStep(
                id: "step-2",
                scheduledTime: Date().addingTimeInterval(-3300),
                title: "Take Metro",
                description: "Board the metro to the stadium.",
                icon: "tram.fill",
                estimatedDuration: 30,
                stepType: .transit
            ),
            ScheduleStep(
                id: "step-3",
                scheduledTime: Date().addingTimeInterval(-1800),
                title: "Arrive at Stadium",
                description: "Walk to the recommended entry gate.",
                icon: "building.2.fill",
                estimatedDuration: 5,
                stepType: .arrival
            )
        ],
        recommendedGate: mockGame.stadium.entryGates[0],
        purchaseDate: Date(),
        arrivalPreference: .balanced,
        transportationMode: .publicTransit,
        parkingReservation: nil,
        foodOrder: nil,
        confidenceScore: 92
    )

    ScheduleTimelineView(schedule: mockSchedule)
}
