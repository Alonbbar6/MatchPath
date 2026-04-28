import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Alternative Layout B: Feature-Separated Modular Design
/// Features are separated into distinct modules accessible from a main hub
struct ModularContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Hub/Dashboard
            ModularDashboardView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            // Schedule Module
            ModularScheduleView()
                .tabItem {
                    Label("Schedule", systemImage: "calendar")
                }
                .tag(1)

            // Tickets Module
            ModularTicketsView()
                .tabItem {
                    Label("Tickets", systemImage: "ticket")
                }
                .tag(2)

            // Wayfinding Module
            ModularWayfindingView()
                .tabItem {
                    Label("Navigate", systemImage: "map.fill")
                }
                .tag(3)

            // Travel Module
            ModularTravelView()
                .tabItem {
                    Label("Travel", systemImage: "car.fill")
                }
                .tag(4)
        }
        .accentColor(.blue)
    }
}

// MARK: - Dashboard View (Hub)

struct ModularDashboardView: View {
    @Binding var selectedTab: Int
    @ObservedObject private var layoutPreference = LayoutPreferenceService.shared

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero Section
                    VStack(spacing: 16) {
                        Image(systemName: "sportscourt.fill")
                            .font(.system(size: 70))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text("MatchPath")
                            .font(.system(.title, design: .rounded, weight: .bold))

                        Text("Plan your perfect match day")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)

                    // Quick Actions Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        Button {
                            selectedTab = 1 // Schedule tab
                        } label: {
                            QuickActionCard(
                                icon: "calendar.badge.plus",
                                title: "Build Schedule",
                                color: .blue,
                                badge: nil
                            )
                        }
                        .buttonStyle(.plain)

                        Button {
                            selectedTab = 2 // Tickets tab
                        } label: {
                            QuickActionCard(
                                icon: "ticket.fill",
                                title: "My Tickets",
                                color: .green,
                                badge: nil
                            )
                        }
                        .buttonStyle(.plain)

                        Button {
                            selectedTab = 3 // Wayfinding tab
                        } label: {
                            QuickActionCard(
                                icon: "map.fill",
                                title: "Wayfinding",
                                color: .orange,
                                badge: "NEW"
                            )
                        }
                        .buttonStyle(.plain)

                        Button {
                            selectedTab = 4 // Travel tab
                        } label: {
                            QuickActionCard(
                                icon: "car.fill",
                                title: "Travel & Parking",
                                color: .purple,
                                badge: nil
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)

                    Divider()
                        .padding(.vertical)

                    // Upcoming Matches Preview
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Upcoming Matches")
                                .font(.headline)
                            Spacer()
                            Button("View All") {}
                                .font(.subheadline)
                        }

                        ForEach(SportingEvent.sampleEvents.prefix(2)) { game in
                            CompactGameCard(game: game)
                        }
                    }
                    .padding(.horizontal)

                    Divider()
                        .padding(.vertical)

                    // Layout Mode Switcher
                    LayoutModeSwitcher(layoutPreference: layoutPreference)
                        .padding(.horizontal)
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

// MARK: - Layout Mode Switcher Component

struct LayoutModeSwitcher: View {
    @ObservedObject var layoutPreference: LayoutPreferenceService

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(.blue)
                Text("Experience Mode")
                    .font(.headline)
                Spacer()
            }

            Text("Currently using: \(layoutPreference.layoutStyle.displayName)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Switch to the OTHER mode
            let otherMode: LayoutPreferenceService.LayoutStyle =
                layoutPreference.layoutStyle == .unified ? .modular : .unified

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    layoutPreference.switchLayout(to: otherMode)
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: otherMode.icon)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Switch to \(otherMode.displayName)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(otherMode.description)
                            .font(.caption)
                    }
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .foregroundColor(.white)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(red: 0.949, green: 0.949, blue: 0.969))
        .cornerRadius(16)
    }
}

// MARK: - Schedule Module

struct ModularScheduleView: View {
    @State private var showingBuilder = false
    @State private var selectedSchedule: GameSchedule?
    @ObservedObject private var persistenceService = SchedulePersistenceService.shared

    var body: some View {
        NavigationView {
            VStack {
                if persistenceService.savedSchedules.isEmpty {
                    // Empty state
                    VStack(spacing: 24) {
                        Spacer()

                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 80))
                            .foregroundColor(.blue.opacity(0.6))

                        VStack(spacing: 12) {
                            Text("No Schedules Yet")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text("Create a custom game-day schedule to see your timeline, arrival times, and recommendations")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }

                        Button {
                            showingBuilder = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Build My First Schedule")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.horizontal, 40)

                        Spacer()
                    }
                } else {
                    // List of schedules
                    List {
                        ForEach(persistenceService.savedSchedules) { schedule in
                            Button {
                                selectedSchedule = schedule
                            } label: {
                                ScheduleListRow(schedule: schedule)
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { index in
                                let schedule = persistenceService.savedSchedules[index]
                                persistenceService.deleteSchedule(schedule.id)
                            }
                        }
                    }
                }
            }
            .navigationTitle("My Schedules")
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingBuilder = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                if !persistenceService.savedSchedules.isEmpty {
                    ToolbarItem(placement: .navigationBarLeading) {
                        EditButton()
                    }
                }
                #else
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingBuilder = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                #endif
            }
            .sheet(isPresented: $showingBuilder) {
                ScheduleBuilderView()
            }
            #if os(iOS)
            .fullScreenCover(item: $selectedSchedule) { schedule in
                ScheduleTimelineView(schedule: schedule)
            }
            #else
            .sheet(item: $selectedSchedule) { schedule in
                ScheduleTimelineView(schedule: schedule)
            }
            #endif
        }
        #if os(iOS)
        .navigationViewStyle(.stack)
        #endif
    }
}

// MARK: - Tickets Module

struct ModularTicketsView: View {
    @State private var selectedGame: SportingEvent?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "ticket.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)

                        Text("Your Tickets")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("View ticket info and match details")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)

                    // Ticket List (or empty state)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Upcoming Games")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(SportingEvent.sampleEvents) { game in
                            Button {
                                selectedGame = game
                            } label: {
                                TicketCard(game: game)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 40)
            }
            .navigationTitle("Tickets")
            .sheet(item: $selectedGame) { game in
                TicketDetailView(game: game)
            }
        }
        #if os(iOS)
        .navigationViewStyle(.stack)
        #endif
    }
}

// MARK: - Wayfinding Module

struct ModularWayfindingView: View {
    @State private var selectedSchedule: GameSchedule?
    @State private var showingIndoorCompass = false
    @State private var showingSchedulePicker = false
    @ObservedObject private var persistenceService = SchedulePersistenceService.shared

    var body: some View {
        NavigationView {
            ZStack {
                if persistenceService.savedSchedules.isEmpty {
                    // Empty state - need to create schedule first
                    VStack(spacing: 24) {
                        Spacer()

                        Image(systemName: "map.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.orange.opacity(0.6))

                        VStack(spacing: 12) {
                            Text("No Schedules Yet")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text("Create a game-day schedule to unlock indoor navigation features")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }

                        VStack(spacing: 12) {
                            Text("Navigation Features:")
                                .font(.headline)

                            VStack(alignment: .leading, spacing: 8) {
                                FeatureRow(icon: "safari", text: "AR Indoor Compass")
                                FeatureRow(icon: "figure.walk", text: "Step-by-Step Directions")
                                FeatureRow(icon: "map", text: "Live Stadium Maps")
                                FeatureRow(icon: "person.3.fill", text: "Real-Time Crowd Data")
                            }
                        }
                        .padding()
                        .background(Color(red: 0.949, green: 0.949, blue: 0.969))
                        .cornerRadius(12)
                        .padding(.horizontal, 40)

                        Spacer()
                    }
                } else if let schedule = selectedSchedule {
                    // Show indoor stadium map with sections and amenities
                    IndoorStadiumMapView(schedule: schedule, onIndoorCompass: { })
                } else {
                    // Show schedule picker on first load
                    VStack {
                        Spacer()
                        VStack(spacing: 20) {
                            Image(systemName: "map.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.orange)

                            Text("Select a Schedule")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text("Choose a game to start navigation")
                                .font(.body)
                                .foregroundColor(.secondary)

                            Button {
                                showingSchedulePicker = true
                            } label: {
                                HStack {
                                    Image(systemName: "list.bullet")
                                    Text("Choose Schedule")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal, 40)
                        }
                        Spacer()
                    }
                }
            }
            .navigationTitle("Wayfinding")
            .toolbar {
                if selectedSchedule != nil {
                    #if os(iOS)
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingSchedulePicker = true
                        } label: {
                            Image(systemName: "list.bullet")
                        }
                    }
                    #else
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showingSchedulePicker = true
                        } label: {
                            Image(systemName: "list.bullet")
                        }
                    }
                    #endif
                }
            }
            .sheet(isPresented: $showingSchedulePicker) {
                SchedulePickerSheet(
                    schedules: persistenceService.savedSchedules,
                    selectedSchedule: $selectedSchedule
                )
            }

        }
        #if os(iOS)
        .navigationViewStyle(.stack)
        #endif
    }
}

// MARK: - Wayfinding Map View

struct WayfindingMapView: View {
    let schedule: GameSchedule
    let onIndoorCompass: () -> Void
    @StateObject private var viewModel: MapViewModel
    @State private var hasAdjustedInitialView = false

    init(schedule: GameSchedule, onIndoorCompass: @escaping () -> Void) {
        self.schedule = schedule
        self.onIndoorCompass = onIndoorCompass
        _viewModel = StateObject(wrappedValue: MapViewModel(schedule: schedule))
    }

    var body: some View {
        ZStack {
            // Map
            MapViewRepresentable(
                region: $viewModel.region,
                annotations: viewModel.annotations
            )
            .edgesIgnoringSafeArea(.all)

            // Top info card
            VStack {
                infoCard
                    .padding()

                Spacer()

                // Bottom action buttons
                actionButtons
                    .padding()
            }
        }
        .onAppear {
            print("🗺️ Wayfinding map appeared")

            // Disable auto-follow so we can show both user location and stadium
            viewModel.autoFollowLocation = false
            viewModel.startNavigation()

            // Automatically fit all locations to show both user location and stadium
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if !hasAdjustedInitialView {
                    print("🗺️ Fitting all annotations to show user and stadium")
                    viewModel.fitAllAnnotations()
                    hasAdjustedInitialView = true
                }
            }
        }
        .onDisappear {
            print("🗺️ Wayfinding map disappeared")
            viewModel.stopNavigation()
        }
    }

    private var infoCard: some View {
        VStack(spacing: 12) {
            // Game info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(schedule.game.displayName)
                        .font(.headline)
                    Text(schedule.game.stadium.name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    if let distance = viewModel.formatDistance() {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.caption)
                            Text(distance)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.blue)
                    }

                    if let eta = viewModel.formatETA() {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.caption)
                            Text(eta)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                }
            }

            // Current step
            if let currentStep = viewModel.currentStep {
                Divider()

                HStack(spacing: 12) {
                    Image(systemName: currentStep.icon)
                        .font(.title3)
                        .foregroundColor(.orange)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(currentStep.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(currentStep.timeUntil)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Primary action: Indoor compass
            Button {
                onIndoorCompass()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "safari")
                    Text("Indoor Compass")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: Color.orange.opacity(0.3), radius: 5)
            }

            // Map controls
            HStack(spacing: 12) {
                // Show my location
                Button {
                    viewModel.autoFollowLocation = true
                    viewModel.centerOnCurrentLocation()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.title3)
                        Text("Me")
                            .font(.caption2)
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.1), radius: 5)
                }

                // Show stadium
                Button {
                    viewModel.autoFollowLocation = false
                    viewModel.centerOnStadium()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "building.2.fill")
                            .font(.title3)
                        Text("Stadium")
                            .font(.caption2)
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.1), radius: 5)
                }

                // Show both
                Button {
                    viewModel.autoFollowLocation = false
                    viewModel.fitAllAnnotations()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "map.fill")
                            .font(.title3)
                        Text("Route")
                            .font(.caption2)
                    }
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.1), radius: 5)
                }
            }
        }
    }
}

// MARK: - Schedule Picker Sheet

struct SchedulePickerSheet: View {
    let schedules: [GameSchedule]
    @Binding var selectedSchedule: GameSchedule?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                ForEach(schedules) { schedule in
                    Button {
                        selectedSchedule = schedule
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(schedule.game.displayName)
                                    .font(.headline)

                                Text(schedule.game.formattedKickoff)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                Text(schedule.game.stadium.name)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if selectedSchedule?.id == schedule.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Choose Schedule")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        #if os(iOS)
        .navigationViewStyle(.stack)
        #endif
    }
}

// MARK: - Travel Module

struct ModularTravelView: View {
    @State private var selectedSchedule: GameSchedule?
    @State private var showingMapNavigation = false
    @State private var showingNavigationOptions = false
    @ObservedObject private var persistenceService = SchedulePersistenceService.shared

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "car.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.purple)

                        Text("Travel & Parking")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Get directions and reserve parking")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)

                    if persistenceService.savedSchedules.isEmpty {
                        // Empty state
                        VStack(spacing: 16) {
                            Text("No travel plans yet")
                                .font(.headline)
                            Text("Create a schedule to plan your route")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 60)
                    } else {
                        // List of schedules with travel info
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Your Trips")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(persistenceService.savedSchedules) { schedule in
                                Button {
                                    selectedSchedule = schedule
                                    showingNavigationOptions = true
                                } label: {
                                    TravelScheduleCard(schedule: schedule)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 40)
            }
            .navigationTitle("Travel")
            .sheet(isPresented: $showingNavigationOptions) {
                if let schedule = selectedSchedule {
                    NavigationOptionsSheet(
                        schedule: schedule,
                        onInAppNavigation: {
                            showingNavigationOptions = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showingMapNavigation = true
                            }
                        }
                    )
                }
            }
            #if os(iOS)
            .fullScreenCover(isPresented: $showingMapNavigation) {
                if let schedule = selectedSchedule {
                    NavigationStack {
                        ScheduleMapView(schedule: schedule)
                    }
                }
            }
            #else
            .sheet(isPresented: $showingMapNavigation) {
                if let schedule = selectedSchedule {
                    NavigationStack {
                        ScheduleMapView(schedule: schedule)
                    }
                }
            }
            #endif
        }
        #if os(iOS)
        .navigationViewStyle(.stack)
        #endif
    }
}

// MARK: - Navigation Options Sheet

struct NavigationOptionsSheet: View {
    let schedule: GameSchedule
    let onInAppNavigation: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                Section {
                    // In-App Navigation
                    Button {
                        onInAppNavigation()
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: "map.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                                .frame(width: 40)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("In-App Navigation")
                                    .font(.headline)
                                Text("Track your schedule with live updates")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                } header: {
                    Text("MatchPath Navigation")
                }

                Section {
                    // Apple Maps
                    Button {
                        openAppleMaps()
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: "map")
                                .font(.title2)
                                .foregroundColor(.blue)
                                .frame(width: 40)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Apple Maps")
                                    .font(.headline)
                                Text("Turn-by-turn directions")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "arrow.up.right")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }

                    // Google Maps
                    Button {
                        openGoogleMaps()
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: "globe")
                                .font(.title2)
                                .foregroundColor(.green)
                                .frame(width: 40)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Google Maps")
                                    .font(.headline)
                                Text("Open in Google Maps app")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "arrow.up.right")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                } header: {
                    Text("External Navigation Apps")
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "location.circle.fill")
                                .foregroundColor(.blue)
                            Text("From: \(schedule.userLocation.name)")
                                .font(.subheadline)
                        }

                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.red)
                            Text("To: \(schedule.game.stadium.name)")
                                .font(.subheadline)
                        }

                        if let parking = schedule.parkingReservation {
                            HStack {
                                Image(systemName: "parkingsign.circle.fill")
                                    .foregroundColor(.green)
                                Text("Parking: \(parking.parkingSpot.name)")
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Trip Details")
                }
            }
            .navigationTitle("Choose Navigation")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        #if os(iOS)
        .navigationViewStyle(.stack)
        #endif
    }

    private func openAppleMaps() {
        let coordinate = schedule.game.stadium.coordinate
        let name = schedule.game.stadium.name

        #if canImport(UIKit)
        // Use Apple Maps app URL scheme for better integration (iOS)
        var urlComponents = URLComponents()
        urlComponents.scheme = "maps"
        urlComponents.host = ""
        urlComponents.queryItems = [
            URLQueryItem(name: "daddr", value: "\(coordinate.latitude),\(coordinate.longitude)"),
            URLQueryItem(name: "q", value: name),
            URLQueryItem(name: "dirflg", value: "d") // d = driving
        ]

        if let userCoordinate = schedule.userLocation.coordinate as Coordinate? {
            urlComponents.queryItems?.append(
                URLQueryItem(name: "saddr", value: "\(userCoordinate.latitude),\(userCoordinate.longitude)")
            )
        }

        if let url = urlComponents.url {
            print("🗺️ Opening Apple Maps: \(url.absoluteString)")
            UIApplication.shared.open(url) { success in
                if success {
                    print("✅ Apple Maps opened successfully")
                } else {
                    print("❌ Failed to open Apple Maps")
                }
            }
            dismiss()
        } else {
            print("❌ Failed to create Apple Maps URL")
        }
        #else
        // macOS: open in Maps via URL or use NSWorkspace
        let urlString = "http://maps.apple.com/?daddr=\(coordinate.latitude),\(coordinate.longitude)&dirflg=d&q=\(name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
            dismiss()
        }
        #endif
    }

    private func openGoogleMaps() {
        let coordinate = schedule.game.stadium.coordinate

        #if canImport(UIKit)
        // Build Google Maps URL with origin if available (iOS)
        var googleMapsURL = "comgooglemaps://?daddr=\(coordinate.latitude),\(coordinate.longitude)&directionsmode=driving"

        if let userCoordinate = schedule.userLocation.coordinate as Coordinate? {
            googleMapsURL += "&saddr=\(userCoordinate.latitude),\(userCoordinate.longitude)"
        }

        if let appUrl = URL(string: googleMapsURL),
           UIApplication.shared.canOpenURL(appUrl) {
            print("🗺️ Opening Google Maps app")
            UIApplication.shared.open(appUrl) { success in
                if success {
                    print("✅ Google Maps app opened successfully")
                } else {
                    print("❌ Failed to open Google Maps app")
                }
            }
            dismiss()
        } else {
            // Fallback to Google Maps website
            var webUrl = "https://www.google.com/maps/dir/?api=1&destination=\(coordinate.latitude),\(coordinate.longitude)"
            if let userCoordinate = schedule.userLocation.coordinate as Coordinate? {
                webUrl += "&origin=\(userCoordinate.latitude),\(userCoordinate.longitude)"
            }
            webUrl += "&travelmode=driving"

            if let url = URL(string: webUrl) {
                print("🗺️ Opening Google Maps web")
                UIApplication.shared.open(url) { success in
                    if success {
                        print("✅ Google Maps web opened successfully")
                    } else {
                        print("❌ Failed to open Google Maps web")
                    }
                }
                dismiss()
            } else {
                print("❌ Failed to create Google Maps web URL")
            }
        }
        #else
        // macOS: open Google Maps web
        var webUrl = "https://www.google.com/maps/dir/?api=1&destination=\(coordinate.latitude),\(coordinate.longitude)"
        if let userCoordinate = schedule.userLocation.coordinate as Coordinate? {
            webUrl += "&origin=\(userCoordinate.latitude),\(userCoordinate.longitude)"
        }
        webUrl += "&travelmode=driving"
        if let url = URL(string: webUrl) {
            NSWorkspace.shared.open(url)
            dismiss()
        }
        #endif
    }
}

// MARK: - Supporting Components

struct QuickActionCard: View {
    let icon: String
    let title: String
    let color: Color
    let badge: String?

    var body: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(color)

                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .cornerRadius(8)
                        .offset(x: 10, y: -10)
                }
            }

            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(Color(red: 0.949, green: 0.949, blue: 0.969))
        .cornerRadius(16)
    }
}

struct CompactGameCard: View {
    let game: SportingEvent

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(game.displayName)
                    .font(.headline)
                Text(game.formattedKickoff)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(game.stadium.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(red: 0.949, green: 0.949, blue: 0.969))
        .cornerRadius(12)
    }
}

// Premium unlock card removed - app is now free

struct TicketCard: View {
    let game: SportingEvent

    var body: some View {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "ticket.fill")
                    .foregroundColor(.green)
                Spacer()
                Text(formatter.string(from: game.kickoffTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(game.displayName)
                .font(.headline)

            HStack {
                Image(systemName: "location.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(game.stadium.name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack {
                Image(systemName: "clock.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(timeFormatter.string(from: game.kickoffTime))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.949, green: 0.949, blue: 0.969))
        .cornerRadius(12)
    }
}

struct TicketDetailView: View {
    let game: SportingEvent
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"

        return NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // QR Code placeholder
                    Image(systemName: "qrcode")
                        .font(.system(size: 200))
                        .foregroundColor(.black)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)

                    VStack(alignment: .leading, spacing: 16) {
                        Text(game.displayName)
                            .font(.title2)
                            .fontWeight(.bold)

                        InfoRow(icon: "calendar", title: "Date", value: formatter.string(from: game.kickoffTime))
                        InfoRow(icon: "clock", title: "Time", value: timeFormatter.string(from: game.kickoffTime))
                        InfoRow(icon: "location.fill", title: "Venue", value: game.stadium.name)
                        InfoRow(icon: "mappin.circle", title: "Address", value: game.stadium.address)
                    }
                    .padding()
                    .background(Color(red: 0.949, green: 0.949, blue: 0.969))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Ticket Details")
            #if !os(macOS)
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
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
            }
        }
    }
}

struct ScheduleListRow: View {
    let schedule: GameSchedule

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(schedule.game.displayName)
                .font(.headline)
            Text(schedule.game.formattedKickoff)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(schedule.game.stadium.name)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
    }
}

struct TravelScheduleCard: View {
    let schedule: GameSchedule

    private func calculateTravelTime(_ schedule: GameSchedule) -> Int {
        // Calculate travel time from schedule steps (departure to arrival)
        if let departureStep = schedule.scheduleSteps.first(where: { $0.stepType == .departure }),
           let arrivalStep = schedule.scheduleSteps.first(where: { $0.stepType == .arrival || $0.stepType == .parking }) {
            let travelTimeInterval = arrivalStep.scheduledTime.timeIntervalSince(departureStep.scheduledTime)
            return Int(travelTimeInterval / 60) // Convert to minutes
        }
        return 30 // Default fallback
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Game Info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(schedule.game.displayName)
                        .font(.headline)
                    Text(schedule.game.formattedKickoff)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }

            Divider()

            // Route Info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "location.circle.fill")
                        .foregroundColor(.blue)
                        .frame(width: 20)
                    Text(schedule.userLocation.name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Image(systemName: "arrow.down")
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    Text("\(calculateTravelTime(schedule)) min travel time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.red)
                        .frame(width: 20)
                    Text(schedule.game.stadium.name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            // Transportation & Parking Info
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Image(systemName: "car.fill")
                        .foregroundColor(.purple)
                    Text(schedule.transportationMode.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                }

                if let parking = schedule.parkingReservation {
                    HStack(spacing: 6) {
                        Image(systemName: "parkingsign.circle.fill")
                            .foregroundColor(.green)
                        Text(parking.parkingSpot.name)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }

                Spacer()
            }

            // Navigation Button
            HStack {
                Image(systemName: "map.fill")
                    .foregroundColor(.white)
                Text("Start Navigation")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "arrow.right")
                    .foregroundColor(.white)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.blue)
            .cornerRadius(8)
        }
        .padding()
        .background(Color(red: 0.949, green: 0.949, blue: 0.969))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    ModularContentView()
}
