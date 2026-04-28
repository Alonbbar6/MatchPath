import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showingScheduleBuilder = false
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                // Main Schedule Builder Tab
                ScheduleBuilderHomeView(onBuildSchedule: {
                    showingScheduleBuilder = true
                })
                .tabItem {
                    Label("Build Schedule", systemImage: "calendar.badge.plus")
                }
                .tag(0)
                
                // My Schedules (replaces old Matches view)
                MySchedulesView()
                    .tabItem {
                        Label("My Schedules", systemImage: "list.bullet.clipboard")
                    }
                    .tag(1)
                
                // Help & Settings
                AppSettingsView()
                    .tabItem {
                        Label("Help", systemImage: "questionmark.circle")
                    }
                    .tag(2)
            }
            .accentColor(.blue)
        }
        .sheet(isPresented: $showingScheduleBuilder) {
            ScheduleBuilderView()
        }
    }
}

// MARK: - Schedule Builder Home View

struct ScheduleBuilderHomeView: View {
    let onBuildSchedule: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Hero Section
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Never Miss Game Time Again")
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            .multilineTextAlignment(.center)
                        
                        Text("Get a custom game-day schedule. Real-time crowd updates and optimized routes to help you arrive on time.")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 40)
                    
                    // CTA Button
                    Button {
                        onBuildSchedule()
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Build My Schedule")
                            Image(systemName: "sparkles")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.horizontal)


                    // Trust Indicators
                    HStack(spacing: 24) {
                        TrustBadge(icon: "lock.shield.fill", text: "Secure")
                        TrustBadge(icon: "clock.fill", text: "Instant")
                        TrustBadge(icon: "checkmark.seal.fill", text: "Reliable")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    Divider()
                        .padding(.vertical)
                    
                    // How It Works
                    VStack(alignment: .leading, spacing: 24) {
                        Text("How It Works")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        HowItWorksStep(
                            number: 1,
                            title: "Select Your Event",
                            description: "Choose your event and venue"
                        )
                        
                        HowItWorksStep(
                            number: 2,
                            title: "Enter Your Location",
                            description: "Tell us where you're staying"
                        )
                        
                        HowItWorksStep(
                            number: 3,
                            title: "Get Your Schedule",
                            description: "Receive a custom timeline with real-time updates"
                        )
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.vertical)
                    
                    // App Info
                    VStack(spacing: 16) {
                        Text("MatchPath Schedule Builder")
                            .font(.headline)

                        Text("Plan your perfect game day experience")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 40)
            }
            .navigationTitle("MatchPath")
        }
        #if os(iOS)
        .navigationViewStyle(.stack)
        #endif
    }
}

struct TrustBadge: View {
    let icon: String
    let text: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
            Text(text)
                .font(.caption)
        }
    }
}

struct HowItWorksStep: View {
    let number: Int
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
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
                    Text("\(number)")
                        .font(.headline)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - My Schedules View

struct MySchedulesView: View {
    @ObservedObject private var persistenceService = SchedulePersistenceService.shared
    @State private var selectedSchedule: GameSchedule?

    var body: some View {
        NavigationView {
            Group {
                if persistenceService.savedSchedules.isEmpty {
                    // Empty state
                    emptyState
                } else {
                    // List of schedules
                    schedulesList
                }
            }
            .navigationTitle("My Schedules")
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !persistenceService.savedSchedules.isEmpty {
                        EditButton()
                    }
                }
                #endif
            }
        }
        #if os(iOS)
        .navigationViewStyle(.stack)
        #endif
        // Platform-appropriate presentation
        #if os(iOS) || os(tvOS) || os(visionOS)
        .fullScreenCover(item: $selectedSchedule) { schedule in
            ScheduleTimelineView(schedule: schedule)
        }
        #else
        .sheet(item: $selectedSchedule) { schedule in
            ScheduleTimelineView(schedule: schedule)
        }
        #endif
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Schedules Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Build your first game-day schedule to see it here")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

        }
        .padding()
    }

    private var schedulesList: some View {
        List {
            // Active schedules (today's games)
            if !persistenceService.activeSchedules.isEmpty {
                Section {
                    ForEach(persistenceService.activeSchedules) { schedule in
                        ScheduleRow(schedule: schedule)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedSchedule = schedule
                            }
                    }
                    .onDelete { indexSet in
                        deleteSchedules(at: indexSet, from: persistenceService.activeSchedules)
                    }
                } header: {
                    Text("Active Today")
                        .font(.headline)
                }
            }

            // Upcoming schedules
            if !persistenceService.upcomingSchedules.isEmpty {
                Section {
                    ForEach(persistenceService.upcomingSchedules) { schedule in
                        ScheduleRow(schedule: schedule)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedSchedule = schedule
                            }
                    }
                    .onDelete { indexSet in
                        deleteSchedules(at: indexSet, from: persistenceService.upcomingSchedules)
                    }
                } header: {
                    Text("Upcoming")
                        .font(.headline)
                }
            }

            // Past schedules
            if !persistenceService.pastSchedules.isEmpty {
                Section {
                    ForEach(persistenceService.pastSchedules) { schedule in
                        ScheduleRow(schedule: schedule)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedSchedule = schedule
                            }
                    }
                    .onDelete { indexSet in
                        deleteSchedules(at: indexSet, from: persistenceService.pastSchedules)
                    }
                } header: {
                    Text("Past Games")
                        .font(.headline)
                }
            }
        }
    }

    private func deleteSchedules(at offsets: IndexSet, from schedules: [GameSchedule]) {
        for index in offsets {
            let schedule = schedules[index]
            persistenceService.deleteSchedule(schedule.id)
        }
    }
}

// MARK: - Schedule Row Component

struct ScheduleRow: View {
    let schedule: GameSchedule

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Game info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(schedule.game.displayName)
                        .font(.headline)

                    Text(schedule.game.stadium.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if schedule.isActive {
                    Label("Live", systemImage: "circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }

            // Kickoff time
            HStack {
                Image(systemName: "clock.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(schedule.game.formattedKickoff)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Transportation & extras
            HStack(spacing: 16) {
                Label(schedule.transportationMode.rawValue, systemImage: schedule.transportationMode.icon)
                    .font(.caption)
                    .foregroundColor(.blue)

                if schedule.hasParking {
                    Label("Parking", systemImage: "parkingsign.circle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }

                if schedule.hasFoodOrder {
                    Label("Food", systemImage: "takeoutbag.and.cup.and.straw.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }

            // Next step (if active)
            if schedule.isActive, let nextStep = schedule.nextStep {
                HStack {
                    Image(systemName: nextStep.icon)
                        .font(.caption)
                        .foregroundColor(.purple)
                    Text("Next: \(nextStep.title) at \(nextStep.formattedTime)")
                        .font(.caption)
                        .foregroundColor(.purple)
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    ContentView()
}
