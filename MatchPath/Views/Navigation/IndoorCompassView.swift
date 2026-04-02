import SwiftUI
import CoreLocation
import Combine
import Foundation

/// AR-style compass view for indoor seat navigation
/// Shows direction arrow, distance, and step-by-step instructions
struct IndoorCompassView: View {
    let schedule: GameSchedule
    @Environment(\.dismiss) private var dismiss
    @StateObject private var compassViewModel: IndoorCompassViewModel
    @State private var showingSteps = false
    @State private var showingDemoSettings = false
    @State private var showingSearch = false
    @State private var isARMode = false

    init(schedule: GameSchedule) {
        self.schedule = schedule
        _compassViewModel = StateObject(wrappedValue: IndoorCompassViewModel(schedule: schedule))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if isARMode {
                    // AR Camera View
                    ARCompassView(viewModel: compassViewModel)
                        .edgesIgnoringSafeArea(.all)
                } else {
                    // 2D Compass View
                    Color(red: 0.949, green: 0.949, blue: 0.969)
                        .ignoresSafeArea()

                    if let directions = compassViewModel.directions {
                        ScrollView {
                            VStack(spacing: 24) {
                                // AR Compass Display
                                compassDisplay(directions: directions)
                                    .padding(.top, 20)

                                // Stadium Floor Map
                                stadiumFloorMap(directions: directions)
                                    .padding(.horizontal)

                                // Step-by-step instructions
                                instructionsPanel(directions: directions)
                                    .padding(.horizontal)
                                    .padding(.bottom, 40)
                            }
                        }
                    } else {
                        // Loading or error state
                        loadingView
                    }
                }
            }
            .navigationTitle("Indoor Navigation")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                            Text("Close")
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        // Search button
                        Button {
                            showingSearch = true
                        } label: {
                            Image(systemName: "magnifyingglass")
                        }

                        // More options menu
                        Menu {
                            Button {
                                withAnimation {
                                    isARMode.toggle()
                                }
                            } label: {
                                Label(isARMode ? "2D Compass" : "AR Camera", systemImage: isARMode ? "map" : "camera.fill")
                            }

                            Button {
                                showingSearch = true
                            } label: {
                                Label("Search Destination", systemImage: "magnifyingglass")
                            }

                            Divider()

                            Button {
                                compassViewModel.refreshDirections()
                            } label: {
                                Label("Refresh", systemImage: "arrow.clockwise")
                            }

                            Button {
                                showingDemoSettings = true
                            } label: {
                                Label("Park Demo Settings", systemImage: "location.circle")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                            Text("Close")
                        }
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            withAnimation {
                                isARMode.toggle()
                            }
                        } label: {
                            Label(isARMode ? "2D Compass" : "AR Camera", systemImage: isARMode ? "map" : "camera.fill")
                        }
                        
                        Divider()
                        
                        Button {
                            compassViewModel.refreshDirections()
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        
                        Button {
                            showingDemoSettings = true
                        } label: {
                            Label("Park Demo Settings", systemImage: "location.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                #endif
            }
            .sheet(isPresented: $showingDemoSettings) {
                ParkDemoSettingsView()
            }
            .sheet(isPresented: $showingSearch) {
                NavigationSearchView(
                    destinations: compassViewModel.allDestinations,
                    currentDestination: compassViewModel.selectedDestination,
                    onSelect: { destination in
                        compassViewModel.selectDestination(destination)
                    }
                )
            }
        }
    }

    // MARK: - Compass Display

    @ViewBuilder
    private func compassDisplay(directions: SeatNavigationDirections) -> some View {
        VStack(spacing: 20) {
            // Stadium name
            Text(directions.stadiumName)
                .font(.headline)
                .foregroundColor(.secondary)

            // Destination info (tappable to search)
            VStack(spacing: 8) {
                Button {
                    showingSearch = true
                } label: {
                    HStack(spacing: 8) {
                        Text(compassViewModel.targetName)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        Image(systemName: "chevron.down.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.blue.opacity(0.6))
                    }
                }
                .buttonStyle(.plain)
                
                if compassViewModel.isDemoMode {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                        Text("DEMO MODE")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.orange)
                    .cornerRadius(12)
                }
            }

            // Large directional arrow
            ZStack {
                // Compass background circle
                Circle()
                    .stroke(Color.blue.opacity(0.3), lineWidth: 3)
                    .frame(width: 280, height: 280)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.1), Color.green.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 280, height: 280)

                // Cardinal directions
                ForEach(["N", "E", "S", "W"], id: \.self) { direction in
                    Text(direction)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                        .offset(y: direction == "N" ? -140 : direction == "S" ? 140 : 0)
                        .offset(x: direction == "E" ? 140 : direction == "W" ? -140 : 0)
                }

                // Direction arrow
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 120))
                    .foregroundColor(.green)
                    .shadow(color: .green.opacity(0.5), radius: 20)
                    .rotationEffect(.degrees(compassViewModel.isDemoMode ? compassViewModel.dynamicBearing : directions.compassBearing))
                    .animation(.easeInOut(duration: 0.3), value: compassViewModel.isDemoMode ? compassViewModel.dynamicBearing : directions.compassBearing)

                // Center dot
                Circle()
                    .fill(Color.primary)
                    .frame(width: 12, height: 12)
            }
            .padding(.vertical, 30)

            // Distance and time stats
            HStack(spacing: 40) {
                VStack(spacing: 8) {
                    Image(systemName: "ruler")
                        .font(.title2)
                        .foregroundColor(.blue)
                    Text("\(compassViewModel.isDemoMode ? compassViewModel.dynamicDistance : directions.totalDistance)m")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("Distance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()
                    .frame(height: 60)

                VStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                    Text("\(directions.estimatedTimeMinutes) min")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("Walking")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(red: 0.949, green: 0.949, blue: 0.969))
            .cornerRadius(16)
        }
    }

    // MARK: - Stadium Floor Map

    @ViewBuilder
    private func stadiumFloorMap(directions: SeatNavigationDirections) -> some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "map.fill")
                    .foregroundColor(.blue)
                Text("Stadium Floor Map")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                // User position indicator
                if compassViewModel.isDemoMode {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                        Text("Live")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding()
            .background(Color(red: 0.949, green: 0.949, blue: 0.969))

            // Embedded floor map with user position
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                ZStack {
                    // Reuse the stadium layout from IndoorStadiumMapView's mock data
                    StadiumMiniMapView(
                        userDisplayX: compassViewModel.userDisplayX,
                        userDisplayY: compassViewModel.userDisplayY,
                        targetSectionId: directions.section.sectionId
                    )
                    .frame(width: 800, height: 800)
                }
            }
            .frame(height: 350)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.95, green: 0.95, blue: 0.97),
                        Color(red: 0.92, green: 0.92, blue: 0.95)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
    }

    // MARK: - Instructions Panel

    @ViewBuilder
    private func instructionsPanel(directions: SeatNavigationDirections) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header - Tappable to expand/collapse
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingSteps.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "list.bullet")
                        .foregroundColor(.blue)
                    Text("Step-by-Step Directions")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: showingSteps ? "chevron.down" : "chevron.up")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14, weight: .semibold))
                }
                .padding()
                .background(Color(red: 0.949, green: 0.949, blue: 0.969))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Steps - Collapsible
            if showingSteps {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(Array(directions.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 12) {
                            // Step number
                            ZStack {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 36, height: 36)

                                Text("\(index + 1)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Image(systemName: step.icon)
                                        .foregroundColor(.blue)
                                        .font(.system(size: 18))
                                    Text(step.title)
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(.primary)
                                }

                                Text(step.description)
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)

                                if step.distance > 0 {
                                    Text("\(step.distance)m")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                        .padding(.top, 2)
                                }
                            }

                            Spacer()
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    }

                    // Nearby amenities
                    if !directions.nearbyRestrooms.isEmpty || !directions.nearbyConcessions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Nearby Amenities")
                                .font(.headline)
                                .foregroundColor(.primary)

                            if !directions.nearbyRestrooms.isEmpty {
                                ForEach(directions.nearbyRestrooms.prefix(2), id: \.id) { restroom in
                                    HStack {
                                        Image(systemName: "toilet")
                                            .foregroundColor(.blue)
                                        Text(restroom.name)
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                    }
                                }
                            }

                            if !directions.nearbyConcessions.isEmpty {
                                ForEach(directions.nearbyConcessions.prefix(2), id: \.id) { concession in
                                    HStack {
                                        Image(systemName: "cup.and.saucer")
                                            .foregroundColor(.orange)
                                        Text(concession.name)
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color(red: 0.949, green: 0.949, blue: 0.969))
                        .cornerRadius(12)
                    }
                }
                .padding()
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(Color.white)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20))
        .shadow(color: Color.black.opacity(0.1), radius: 10, y: -5)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)

            Text("Loading navigation data...")
                .foregroundColor(.white)
        }
    }
}

// MARK: - View Model

class IndoorCompassViewModel: ObservableObject {
    @Published var directions: SeatNavigationDirections?
    @Published var currentHeading: Double = 0
    @Published var dynamicBearing: Double = 0
    @Published var dynamicDistance: Int = 0
    @Published var isDemoMode: Bool = false
    @Published var userLocalX: Double = 0
    @Published var userLocalY: Double = 0
    @Published var userDisplayX: CGFloat = 650
    @Published var userDisplayY: CGFloat = 610

    // Search & dynamic destination
    @Published var allDestinations: [NavigationDestination] = []
    @Published var selectedDestination: NavigationDestination?
    @Published var targetLocalX: Double = 0
    @Published var targetLocalY: Double = 0
    @Published var targetName: String = "Section 101"

    private let schedule: GameSchedule
    private let wayfindingService = IndoorWayfindingService.shared
    private let locationManager = LocationManager.shared
    private let parkDemoService = ParkDemoService.shared
    private var cancellables = Set<AnyCancellable>()

    init(schedule: GameSchedule) {
        self.schedule = schedule
        Task {
            await loadDirections()
            await loadDestinations()
        }
        setupSubscriptions()
    }

    private func setupSubscriptions() {
        // Subscribe to heading updates
        locationManager.$currentHeading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] heading in
                self?.currentHeading = heading
                self?.updateDynamicBearing()
            }
            .store(in: &cancellables)

        // Subscribe to location updates for demo mode
        locationManager.$currentLocation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                guard let self = self, self.isDemoMode else { return }
                self.updateDemoPosition()
            }
            .store(in: &cancellables)

        // Subscribe to demo mode changes
        parkDemoService.$isEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                self?.isDemoMode = enabled
                if enabled {
                    self?.locationManager.startHeadingTracking()
                    self?.locationManager.setHighAccuracyMode(true)
                } else {
                    self?.locationManager.stopHeadingTracking()
                    self?.locationManager.setHighAccuracyMode(false)
                }
            }
            .store(in: &cancellables)
    }

    private func updateDynamicBearing() {
        guard isDemoMode else { return }
        // Use selected destination or fallback to directions section
        let tX = targetLocalX
        let tY = targetLocalY
        let dx = tX - userLocalX
        let dy = tY - userLocalY
        let angle = atan2(dy, dx) * 180 / .pi
        let bearing = (90 - angle + 360).truncatingRemainder(dividingBy: 360)
        dynamicBearing = bearing - currentHeading
    }

    private func updateDemoPosition() {
        guard let location = locationManager.currentLocation,
              let stadiumData = wayfindingService.getStadiumData(for: schedule.game.stadium.id) else {
            return
        }

        // Transform GPS to stadium coordinates
        let stadiumCoord = parkDemoService.gpsToStadiumCoordinates(
            gpsLat: location.coordinate.latitude,
            gpsLon: location.coordinate.longitude,
            stadiumData: stadiumData
        )

        // Store local position for floor map display
        userLocalX = stadiumCoord.x
        userLocalY = stadiumCoord.y
        userDisplayX = CGFloat(stadiumCoord.x * 4.0 + 650)
        userDisplayY = CGFloat(stadiumCoord.y * -3.83 + 610)

        // Calculate distance to selected destination
        let dx = targetLocalX - stadiumCoord.x
        let dy = targetLocalY - stadiumCoord.y
        let distanceInStadiumUnits = sqrt(dx * dx + dy * dy)
        dynamicDistance = Int(distanceInStadiumUnits)

        // Calculate bearing to target
        let angle = atan2(dy, dx) * 180 / .pi
        let bearing = (90 - angle + 360).truncatingRemainder(dividingBy: 360)
        dynamicBearing = bearing - currentHeading
    }

    // MARK: - Destination Selection

    func selectDestination(_ destination: NavigationDestination) {
        selectedDestination = destination
        targetLocalX = destination.localX
        targetLocalY = destination.localY
        targetName = destination.name

        // Recalculate bearing and distance from current position
        if isDemoMode {
            updateDemoPosition()
        } else {
            // Static mode: calculate from gate position
            let dx = destination.localX - userLocalX
            let dy = destination.localY - userLocalY
            dynamicDistance = Int(sqrt(dx * dx + dy * dy))
            let angle = atan2(dy, dx) * 180 / .pi
            dynamicBearing = (90 - angle + 360).truncatingRemainder(dividingBy: 360)
        }
    }

    @MainActor
    private func loadDestinations() async {
        await wayfindingService.ensureDataLoaded()
        guard let stadiumData = wayfindingService.getStadiumData(for: schedule.game.stadium.id) else { return }

        var destinations: [NavigationDestination] = []

        // Sections
        for section in stadiumData.sections {
            destinations.append(NavigationDestination(
                id: section.sectionId,
                name: "Section \(section.sectionId)",
                category: .section,
                localX: section.localX,
                localY: section.localY,
                detail: "\(section.level) \u{2022} \(section.totalSeats) seats"
            ))
        }

        // Gates
        for gate in stadiumData.gates {
            destinations.append(NavigationDestination(
                id: gate.id,
                name: gate.name,
                category: .gate,
                localX: gate.localX,
                localY: gate.localY,
                detail: gate.accessible ? "Accessible" : nil
            ))
        }

        // Amenities
        for amenity in stadiumData.amenities {
            let category: NavigationDestination.DestinationCategory
            switch amenity.type {
            case "restroom":
                category = .restroom
            case "concession":
                category = .concession
            default:
                category = .concession
            }

            var detail: String?
            if amenity.type == "restroom" {
                var parts: [String] = []
                if let gender = amenity.gender { parts.append(gender.capitalized) }
                if amenity.familyRestroom == true { parts.append("Family") }
                if amenity.accessible == true { parts.append("Accessible") }
                detail = parts.isEmpty ? nil : parts.joined(separator: " \u{2022} ")
            } else if amenity.type == "concession" {
                detail = amenity.vendors?.joined(separator: ", ")
            }

            destinations.append(NavigationDestination(
                id: amenity.id,
                name: amenity.name,
                category: category,
                localX: amenity.localX,
                localY: amenity.localY,
                detail: detail
            ))
        }

        allDestinations = destinations
    }

    func loadDirections() async {
        print("🔍 IndoorCompassViewModel: Starting loadDirections()")

        // Ensure stadium data is loaded first
        print("🔍 IndoorCompassViewModel: Ensuring data loaded...")
        await wayfindingService.ensureDataLoaded()
        print("✅ IndoorCompassViewModel: Data ensure complete")

        let stadium = schedule.game.stadium
        let recommendedGate = schedule.recommendedGate

        print("🔍 IndoorCompassViewModel: Stadium info:")
        print("   - Stadium ID: \(stadium.id)")
        print("   - Stadium Name: \(stadium.name)")
        print("   - Recommended Gate: \(recommendedGate.name)")

        // Map gate name to navigation data gate ID
        // Dynamically match by looking for direction keywords in the recommended gate name
        var gateId: String?
        let gateName = recommendedGate.name.lowercased()
        if gateName.contains("north") { gateId = "gate-north" }
        else if gateName.contains("south") { gateId = "gate-south" }
        else if gateName.contains("east") { gateId = "gate-east" }
        else if gateName.contains("west") { gateId = "gate-west" }
        else { gateId = "gate-north" } // Default to north gate

        print("🔍 IndoorCompassViewModel: Gate mapping result: \(gateId ?? "nil")")

        // Get sample section (in production, this would come from user's ticket)
        let sectionId = "101"
        print("🔍 IndoorCompassViewModel: Target section: \(sectionId)")

        if let gateId = gateId {
            print("🔍 IndoorCompassViewModel: Calling getDirections...")
            let result = wayfindingService.getDirections(
                from: gateId,
                to: sectionId,
                in: stadium.id
            )

            if let result = result {
                print("✅ IndoorCompassViewModel: Directions generated successfully")
                print("   - Total distance: \(result.totalDistance)m")
                print("   - Steps: \(result.steps.count)")
            } else {
                print("❌ IndoorCompassViewModel: getDirections returned nil")
            }

            // Update on main thread
            await MainActor.run {
                directions = result
                // Default user position to the gate entrance
                if let result = result {
                    userLocalX = result.gate.localX
                    userLocalY = result.gate.localY
                    userDisplayX = CGFloat(result.gate.localX * 4.0 + 650)
                    userDisplayY = CGFloat(result.gate.localY * -3.83 + 610)
                    // Set initial target to the section from directions
                    targetLocalX = result.section.localX
                    targetLocalY = result.section.localY
                    targetName = "Section \(result.section.sectionId)"
                }
                print("✅ IndoorCompassViewModel: UI updated with directions")
            }
        } else {
            print("❌ IndoorCompassViewModel: No gateId mapped, cannot get directions")
        }
    }

    func refreshDirections() {
        Task {
            await loadDirections()
        }
    }
}

// MARK: - Preview

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

    IndoorCompassView(schedule: mockSchedule)
}
