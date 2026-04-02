import SwiftUI
import Combine
import CoreLocation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct ScheduleBuilderView: View {
    @StateObject private var viewModel = ScheduleBuilderViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        // Use platform-appropriate navigation container
        #if os(iOS)
        NavigationView {
            content
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
        }
        #else
        NavigationStack {
            content
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
        }
        #endif
    }
    
    // Extract the main content to reduce duplication between platforms
    private var content: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.42, blue: 0.21),  // Passion Orange
                    Color(red: 0.97, green: 0.58, blue: 0.12), // Vibrant Orange
                    Color(red: 0.99, green: 0.78, blue: 0.19), // Golden Yellow
                    Color(red: 0.22, green: 0.70, blue: 0.29), // Victory Green
                    Color(red: 0.12, green: 0.53, blue: 0.90)  // Confidence Blue
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(0.1)
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Build Your Game-Day Schedule")
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .multilineTextAlignment(.center)

                        Text("Create your personalized game-day timeline")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Step 1: Create or Select Event
                    VStack(alignment: .leading, spacing: 16) {
                        StepHeader(number: 1, title: "Your Event")

                        if let selected = viewModel.selectedGame {
                            // Show selected event
                            GameSelectionCard(
                                game: selected,
                                isSelected: true,
                                onTap: { viewModel.clearSelectedGame() }
                            )
                            Button("Change Event") {
                                viewModel.clearSelectedGame()
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        } else {
                            // Event creation form
                            VStack(spacing: 12) {
                                TextField("Event title (e.g., Chiefs vs Eagles)", text: $viewModel.eventTitle)
                                    .textFieldStyle(.roundedBorder)

                                // Category picker
                                HStack {
                                    Text("Category")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Picker("Category", selection: $viewModel.eventCategory) {
                                        ForEach(["NFL", "NBA", "MLB", "NHL", "MLS", "Soccer", "Concert", "Other"], id: \.self) { cat in
                                            Text(cat).tag(cat)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                }

                                DatePicker("Event Date & Time", selection: $viewModel.eventDate, in: Date()...)
                                    .font(.subheadline)

                                // Venue picker
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Venue")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)

                                    if let venue = viewModel.selectedVenue {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(venue.name).font(.headline)
                                                Text(venue.city).font(.caption).foregroundColor(.secondary)
                                            }
                                            Spacer()
                                            Button("Change") { viewModel.showingVenuePicker = true }
                                                .font(.caption)
                                        }
                                    } else {
                                        Button {
                                            viewModel.showingVenuePicker = true
                                        } label: {
                                            HStack {
                                                Image(systemName: "building.2")
                                                Text("Select Venue")
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                            }
                                            .padding(10)
                                            .background(Color.blue.opacity(0.1))
                                            .cornerRadius(8)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }

                                // Create event button
                                Button {
                                    viewModel.createEvent()
                                } label: {
                                    Text("Add Event")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(!viewModel.canCreateEvent)
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
                            .cornerRadius(12)

                            // Show saved events if any
                            let saved = viewModel.savedEvents
                            if !saved.isEmpty {
                                Text("Or select a saved event:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                ForEach(saved) { event in
                                    GameSelectionCard(
                                        game: event,
                                        isSelected: false,
                                        onTap: { viewModel.selectGame(event) }
                                    )
                                }
                            }
                        }
                    }
                    
                    // Step 2: Enter Location
                    if viewModel.selectedGame != nil {
                        VStack(alignment: .leading, spacing: 16) {
                            StepHeader(number: 2, title: "Where Are You Starting From?")

                            VStack(spacing: 12) {
                                TextField("Location name (e.g., Home, Hotel, etc.)", text: $viewModel.locationName)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.body)

                                TextField("Full address or nearest landmark", text: $viewModel.locationAddress)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.body)

                                // Quick location options
                                HStack(spacing: 12) {
                                    Button {
                                        viewModel.useCurrentLocation()
                                    } label: {
                                        HStack(spacing: 6) {
                                            if viewModel.isLoadingLocation {
                                                ProgressView()
                                                    .scaleEffect(0.8)
                                                    .tint(.white)
                                                Text("Getting Location...")
                                                    .font(.caption)
                                            } else {
                                                Image(systemName: "location.fill")
                                                    .font(.caption)
                                                Text("Use My Location")
                                                    .font(.caption)
                                            }
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                    }
                                    .disabled(viewModel.isLoadingLocation)

                                    Button {
                                        viewModel.showingMapPicker = true
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: "map")
                                                .font(.caption)
                                            Text("Select on Map")
                                                .font(.caption)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
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
                            .cornerRadius(12)
                        }
                        .transition(.move(edge: .leading).combined(with: .opacity))
                    }

                    // Step 2.5: Section Number (Optional but Recommended)
                    if viewModel.selectedGame != nil && !viewModel.locationName.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                StepHeader(number: 3, title: "Your Seat Section (Optional)")
                                Spacer()
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                                Text("Recommended")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.yellow)
                            }

                            VStack(alignment: .leading, spacing: 12) {
                                Text("Enter your section number for optimized gate recommendations")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                TextField("Section (e.g., 118, 301, 223)", text: $viewModel.sectionNumber)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.body)
                                    #if os(iOS)
                                    .keyboardType(.numberPad)
                                    #endif

                                HStack(spacing: 6) {
                                    Image(systemName: "info.circle.fill")
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                    Text("We'll recommend the best gate and walking route for your section")
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
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.yellow.opacity(0.3), lineWidth: 2)
                            )
                        }
                        .transition(.move(edge: .leading).combined(with: .opacity))
                    }

                    // Step 4: Choose Transportation Mode
                    if viewModel.selectedGame != nil && !viewModel.locationName.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            StepHeader(number: 4, title: "How Will You Get There?")

                            TransportationModeSelectionView(selectedMode: $viewModel.transportationMode)
                        }
                        .transition(.move(edge: .leading).combined(with: .opacity))
                    }

                    // Step 5: Select Parking (if driving) - OPTIONAL
                    if viewModel.transportationMode.requiresParking && viewModel.selectedGame != nil {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                StepHeader(number: 5, title: "Reserve Your Parking (Optional)")
                                Spacer()
                            }

                            Text("You can reserve parking now or find a spot when you arrive")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)

                            if let parkingSpot = viewModel.selectedParkingSpot {
                                // Show selected parking
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(parkingSpot.name)
                                                .font(.headline)
                                            Text(parkingSpot.priceDisplay)
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }

                                        Spacer()

                                        Button("Change") {
                                            viewModel.showingParkingSelection = true
                                        }
                                        .buttonStyle(.bordered)
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
                                    .cornerRadius(12)

                                    // Remove parking button
                                    Button {
                                        viewModel.selectedParkingSpot = nil
                                    } label: {
                                        Text("Skip Parking")
                                            .font(.subheadline)
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(.plain)
                                }
                            } else {
                                // Show button to select parking
                                VStack(spacing: 12) {
                                    Button {
                                        viewModel.showingParkingSelection = true
                                    } label: {
                                        HStack {
                                            Image(systemName: "parkingsign.circle.fill")
                                            Text("Select Parking Spot")
                                            Spacer()
                                            Image(systemName: "chevron.right")
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
                                        .cornerRadius(12)
                                    }
                                    .buttonStyle(.plain)

                                    Text("or")
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    Button {
                                        // Continue without parking - do nothing, just allow flow to continue
                                    } label: {
                                        Text("Skip Parking - I'll Find a Spot")
                                            .font(.subheadline)
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                        .transition(.move(edge: .leading).combined(with: .opacity))
                    }

                    // Step 6: Choose Arrival Preference
                    if viewModel.selectedGame != nil && !viewModel.locationName.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            StepHeader(
                                number: viewModel.transportationMode.requiresParking ? 6 : 5,
                                title: "How Do You Want to Arrive?"
                            )

                            ForEach(ArrivalPreference.allCases, id: \.self) { preference in
                                PreferenceCard(
                                    preference: preference,
                                    isSelected: viewModel.arrivalPreference == preference,
                                    onTap: { viewModel.selectPreference(preference) }
                                )
                            }
                        }
                        .transition(.move(edge: .leading).combined(with: .opacity))
                    }

                    // Step 7: Pre-Order Food (Optional)
                    if viewModel.canGenerate {
                        VStack(alignment: .leading, spacing: 16) {
                            StepHeader(
                                number: viewModel.transportationMode.requiresParking ? 7 : 6,
                                title: "Pre-Order Food? (Optional)"
                            )

                            Button {
                                viewModel.showingFoodOrdering = true
                            } label: {
                                HStack {
                                    Image(systemName: "fork.knife.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(.orange)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Skip the lines!")
                                            .font(.headline)
                                        Text("Order stadium food ahead of time")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
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
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        .transition(.move(edge: .leading).combined(with: .opacity))
                    }

                    // Generate Button
                    if viewModel.canGenerate {
                        VStack(spacing: 12) {
                            Button {
                                Task {
                                    await viewModel.generateSchedule()
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "sparkles")
                                    Text("Generate My Schedule")
                                    Image(systemName: "sparkles")
                                }
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)

                            Text("Free • Unlimited schedules")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $viewModel.showingSchedule) {
            if let schedule = viewModel.generatedSchedule {
                ScheduleTimelineView(schedule: schedule)
            }
        }
        .sheet(isPresented: $viewModel.showingParkingSelection) {
            if let game = viewModel.selectedGame {
                ParkingSelectionView(
                    stadium: game.stadium,
                    startTime: game.kickoffTime.addingTimeInterval(
                        -(
                            Double(viewModel.arrivalPreference.minutesBeforeKickoff) * 60.0
                        ) - 1800.0 // 30 min before arrival
                    ),
                    endTime: game.kickoffTime.addingTimeInterval(10800.0) // 3 hours after kickoff
                ) { spot in
                    viewModel.selectParkingSpot(spot)
                }
                #if os(iOS)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                #endif
            }
        }
        .sheet(isPresented: $viewModel.showingFoodOrdering) {
            if let game = viewModel.selectedGame {
                FoodAppPickerView(
                    stadium: game.stadium,
                    pickupTime: game.kickoffTime.addingTimeInterval(
                        -Double(viewModel.arrivalPreference.minutesBeforeKickoff) * 60.0
                    )
                )
                #if os(iOS)
                .presentationDetents([.medium, .large])
                #endif
            }
        }
        .sheet(isPresented: $viewModel.showingMapPicker) {
            LocationMapPickerView(
                locationName: $viewModel.locationName,
                locationAddress: $viewModel.locationAddress,
                onLocationSelected: { coordinate in
                    viewModel.setLocation(coordinate: coordinate)
                }
            )
        }
        .sheet(isPresented: $viewModel.showingVenuePicker) {
            VenuePickerView { venue in
                viewModel.selectedVenue = venue
                viewModel.showingVenuePicker = false
            }
            #if os(iOS)
            .presentationDetents([.large])
            #endif
        }
        .alert(viewModel.errorTitle, isPresented: $viewModel.showingError) {
            if viewModel.canRetry {
                Button("Try Again") {
                    viewModel.retryGeneration()
                }
                Button("Cancel", role: .cancel) { }
            } else {
                Button("OK", role: .cancel) { }
            }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

// MARK: - Supporting Views

struct StepHeader: View {
    let number: Int
    let title: String
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32, height: 32)
                .overlay(
                    Text("\(number)")
                        .font(.headline)
                        .foregroundColor(.white)
                )
            
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
        }
    }
}

struct GameSelectionCard: View {
    let game: SportingEvent
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(game.displayName)
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text(game.category)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                }

                Divider()

                HStack(spacing: 16) {
                    Label(game.formattedEventTime, systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Label(game.venue.displayName, systemImage: "building.2")
                        .font(.caption)
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
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        }
        .buttonStyle(.plain)
    }
}

struct PreferenceCard: View {
    let preference: ArrivalPreference
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(preference.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(preference.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Arrive \(preference.minutesBeforeKickoff) min before kickoff")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
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
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ViewModel

@MainActor
class ScheduleBuilderViewModel: ObservableObject {
    @Published var selectedGame: SportingEvent?
    @Published var locationName: String = ""
    @Published var locationAddress: String = ""
    @Published var sectionNumber: String = ""
    @Published var arrivalPreference: ArrivalPreference = .balanced
    @Published var transportationMode: TransportationMode = .driving
    @Published var selectedParkingSpot: ParkingSpot?
    @Published var showingSchedule = false
    @Published var showingParkingSelection = false
    @Published var showingFoodOrdering = false
    @Published var showingMapPicker = false
    @Published var showingVenuePicker = false
    @Published var showingPaywall = false
    @Published var generatedSchedule: GameSchedule?
    @Published var userCoordinate: Coordinate?
    @Published var isLoadingLocation = false

    // Event creation fields
    @Published var eventTitle: String = ""
    @Published var eventCategory: String = "NFL"
    @Published var eventDate: Date = Date().addingTimeInterval(86400) // tomorrow
    @Published var selectedVenue: Stadium?

    // Error handling
    @Published var showingError = false
    @Published var errorTitle = ""
    @Published var errorMessage = ""
    @Published var canRetry = false

    // Services
    private let persistenceService = SchedulePersistenceService.shared
    private let premiumManager = PremiumManager.shared
    private let notificationService = NotificationService.shared
    private let locationManager = LocationManager.shared
    private let eventStore = UserEventStore.shared
    private var locationCancellable: AnyCancellable?

    var canGenerate: Bool {
        guard selectedGame != nil && !locationName.isEmpty && !locationAddress.isEmpty else {
            return false
        }
        return true
    }

    var canCreateEvent: Bool {
        !eventTitle.isEmpty && selectedVenue != nil
    }

    var savedEvents: [SportingEvent] {
        eventStore.upcomingEvents()
    }

    var needsParkingSelection: Bool {
        return transportationMode.requiresParking && selectedParkingSpot == nil
    }

    var canCreateFreeSchedule: Bool {
        return persistenceService.canCreateNewSchedule()
    }

    var isPremiumUser: Bool {
        return premiumManager.isPremium
    }

    func createEvent() {
        guard let venue = selectedVenue else { return }
        let event = SportingEvent(
            id: UUID().uuidString,
            title: eventTitle,
            venue: venue,
            eventTime: eventDate,
            category: eventCategory
        )
        eventStore.addEvent(event)
        selectGame(event)
    }

    func clearSelectedGame() {
        withAnimation {
            selectedGame = nil
        }
    }

    func selectGame(_ game: SportingEvent) {
        withAnimation {
            selectedGame = game
        }
    }
    
    func selectPreference(_ preference: ArrivalPreference) {
        withAnimation {
            arrivalPreference = preference
        }
    }

    func selectParkingSpot(_ spot: ParkingSpot) {
        withAnimation {
            selectedParkingSpot = spot
        }
    }

    func useCurrentLocation() {
        print("📍 Requesting current location...")
        isLoadingLocation = true

        // Request permission if needed
        locationManager.requestPermission()

        // Start tracking to get fresh location
        locationManager.startTracking()

        // Subscribe to location updates
        locationCancellable = locationManager.$currentLocation
            .compactMap { $0 } // Only emit non-nil values
            .first() // Take first location update
            .sink { [weak self] location in
                guard let self = self else { return }

                let coordinate = Coordinate(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )
                self.userCoordinate = coordinate
                self.locationName = "My Current Location"
                self.locationAddress = "GPS: \(String(format: "%.4f", location.coordinate.latitude)), \(String(format: "%.4f", location.coordinate.longitude))"
                self.isLoadingLocation = false

                print("✅ Using current location: \(coordinate.latitude), \(coordinate.longitude)")
            }

        // Set a timeout in case location never arrives
        Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds timeout

            await MainActor.run {
                if self.isLoadingLocation {
                    print("⏱️ Location request timed out")
                    self.isLoadingLocation = false

                    // Use last known location if available, otherwise fallback
                    if let location = self.locationManager.currentLocation {
                        let coordinate = Coordinate(
                            latitude: location.coordinate.latitude,
                            longitude: location.coordinate.longitude
                        )
                        self.userCoordinate = coordinate
                        self.locationName = "My Current Location"
                        self.locationAddress = "GPS: \(String(format: "%.4f", location.coordinate.latitude)), \(String(format: "%.4f", location.coordinate.longitude))"
                        print("✅ Used cached location after timeout")
                    } else {
                        // Complete fallback
                        self.userCoordinate = Coordinate(latitude: 25.7617, longitude: -80.1918)
                        self.locationName = "My Current Location"
                        self.locationAddress = "Location services unavailable - using approximate location"
                        print("❌ No location available - using fallback")
                    }
                }
            }
        }
    }

    func setLocation(coordinate: Coordinate) {
        userCoordinate = coordinate
        locationName = "Selected Location"
        locationAddress = "GPS: \(String(format: "%.4f", coordinate.latitude)), \(String(format: "%.4f", coordinate.longitude))"
        showingMapPicker = false
        print("📍 Location set from map: \(coordinate.latitude), \(coordinate.longitude)")
    }

    func generateSchedule() async {
        guard let game = selectedGame else { return }

        // Create user location - use actual coordinate if available
        let coordinate = userCoordinate ?? Coordinate(latitude: 25.7617, longitude: -80.1918)
        let userLocation = UserLocation(
            name: locationName,
            address: locationAddress,
            coordinate: coordinate
        )

        // Generate schedule with real Google Maps integration and parking
        do {
            let schedule = try await ScheduleGeneratorService.shared.generateSchedule(
                for: game,
                from: userLocation,
                sectionNumber: sectionNumber.isEmpty ? nil : sectionNumber, // Pass section number
                preference: arrivalPreference,
                transportationMode: transportationMode,
                parkingSpot: selectedParkingSpot
            )

            // Update UI on main actor
            await MainActor.run {
                generatedSchedule = schedule
                showingSchedule = true

                // Save the schedule automatically
                if persistenceService.saveSchedule(schedule) {
                    print("✅ Schedule saved successfully!")
                } else {
                    print("❌ Failed to save schedule")
                }
            }

            // Schedule notifications for this schedule
            await notificationService.scheduleNotifications(for: schedule)
        } catch {
            // Handle error - show alert to user
            print("❌ Failed to generate schedule: \(error.localizedDescription)")

            await MainActor.run {
                handleError(error)
            }
        }
    }

    // MARK: - Error Handling

    /// Handle different types of errors and show appropriate alerts
    private func handleError(_ error: Error) {
        print("🚨 Handling error: \(error)")

        // Determine error type and set appropriate message
        let errorString = error.localizedDescription.lowercased()

        if errorString.contains("network") || errorString.contains("internet") || errorString.contains("connection") {
            // Network error
            errorTitle = "Network Error"
            errorMessage = "Unable to connect to the internet. Please check your connection and try again."
            canRetry = true

        } else if errorString.contains("location") || errorString.contains("denied") {
            // Location error
            errorTitle = "Location Access Denied"
            errorMessage = "Please enable location services in Settings to generate personalized schedules."
            canRetry = false

        } else if errorString.contains("api") || errorString.contains("key") {
            // API error
            errorTitle = "Service Temporarily Unavailable"
            errorMessage = "We're experiencing technical difficulties. Please try again in a few moments."
            canRetry = true

        } else if errorString.contains("timeout") {
            // Timeout error
            errorTitle = "Request Timed Out"
            errorMessage = "The request took too long. Please check your internet connection and try again."
            canRetry = true

        } else {
            // Generic error
            errorTitle = "Something Went Wrong"
            errorMessage = "We encountered an unexpected error: \(error.localizedDescription)\n\nPlease try again."
            canRetry = true
        }

        showingError = true
    }

    /// Retry the last failed operation
    func retryGeneration() {
        showingError = false
        Task {
            await generateSchedule()
        }
    }
}

#Preview {
    ScheduleBuilderView()
}
