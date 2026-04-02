import SwiftUI
import MapKit
import Combine

/// View for selecting a parking spot
struct ParkingSelectionView: View {
    let stadium: Stadium
    let startTime: Date
    let endTime: Date
    let onParkingSelected: (ParkingSpot) -> Void

    @StateObject private var viewModel = ParkingSelectionViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingParkingAppPicker = false

    var body: some View {
        // Use platform-appropriate navigation container
        #if os(iOS)
        NavigationView {
            content
                .navigationTitle("Select Parking")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
                .task {
                    await viewModel.searchParking(
                        stadium: stadium,
                        startTime: startTime,
                        endTime: endTime
                    )
                }
        }
        #else
        NavigationStack {
            content
                .navigationTitle("Select Parking")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
                .task {
                    await viewModel.searchParking(
                        stadium: stadium,
                        startTime: startTime,
                        endTime: endTime
                    )
                }
        }
        #endif
    }

    // Extracted to reduce duplication
    private var content: some View {
        Group {
            if viewModel.isLoading {
                LoadingView()
            } else if let error = viewModel.errorMessage {
                ErrorView(message: error) {
                    Task {
                        await viewModel.searchParking(
                            stadium: stadium,
                            startTime: startTime,
                            endTime: endTime
                        )
                    }
                }
            } else {
                parkingListView
            }
        }
    }

    private var parkingListView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header with stadium info
                VStack(spacing: 8) {
                    Text("Parking near \(stadium.name)")
                        .font(.headline)
                    Text(stadium.city)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()

                // Reserve Online button
                Button {
                    showingParkingAppPicker = true
                } label: {
                    HStack {
                        Image(systemName: "app.badge")
                        Text("Reserve Online with ParkMobile/SpotHero")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .foregroundColor(.orange)
                    .cornerRadius(12)
                }
                .padding(.horizontal)

                // Filters
                filterSection

                // Parking spots
                if viewModel.parkingSpots.isEmpty {
                    noParkingView
                } else {
                    ForEach(viewModel.parkingSpots) { spot in
                        ParkingSpotCard(spot: spot) {
                            onParkingSelected(spot)
                            dismiss()
                        }
                    }
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingParkingAppPicker) {
            ParkingAppPickerView(
                parkingSpot: nil,
                location: stadium.coordinate,
                locationName: stadium.name,
                startTime: startTime,
                endTime: endTime
            )
            .presentationDetents([.medium, .large])
        }
    }

    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sort By")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    FilterChip(
                        title: "Distance",
                        isSelected: viewModel.sortOption == .distance
                    ) {
                        viewModel.sortOption = .distance
                    }

                    FilterChip(
                        title: "Price",
                        isSelected: viewModel.sortOption == .price
                    ) {
                        viewModel.sortOption = .price
                    }

                    FilterChip(
                        title: "Walking Time",
                        isSelected: viewModel.sortOption == .walkingTime
                    ) {
                        viewModel.sortOption = .walkingTime
                    }
                }
            }
        }
        .padding(.bottom, 8)
    }

    private var noParkingView: some View {
        VStack(spacing: 16) {
            Image(systemName: "parkingsign.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Parking Available")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Try adjusting your arrival time or check back later")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
    }
}

// MARK: - Parking Spot Card

struct ParkingSpotCard: View {
    let spot: ParkingSpot
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 0) {
                // Main content
                HStack(alignment: .top, spacing: 12) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 60, height: 60)

                        Image(systemName: "parkingsign.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.blue)
                    }

                    // Info
                    VStack(alignment: .leading, spacing: 6) {
                        Text(spot.name)
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text(spot.address)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)

                        HStack(spacing: 12) {
                            Label(spot.distanceDisplay, systemImage: "location.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Label("\(spot.walkingTimeToStadium) min walk", systemImage: "figure.walk")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        // Features
                        if !spot.features.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(spot.features.prefix(3), id: \.self) { feature in
                                        FeatureBadge(feature: feature)
                                    }
                                }
                            }
                        }
                    }

                    Spacer()

                    // Price and availability
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(spot.priceDisplay)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        AvailabilityBadge(status: spot.availabilityStatus)
                    }
                }
                .padding()

                // Available spots indicator
                if spot.availableSpots > 0 {
                    Divider()

                    HStack {
                        Image(systemName: "car.fill")
                            .foregroundColor(.secondary)
                            .font(.caption)

                        Text("\(spot.availableSpots) spots available")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
            }
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
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Supporting Views

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : chipBackground)
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }

    private var chipBackground: Color {
        #if os(iOS)
        return Color(.systemGray6)
        #else
        return Color(nsColor: .controlBackgroundColor)
        #endif
    }
}

struct FeatureBadge: View {
    let feature: ParkingFeature

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: feature.icon)
                .font(.system(size: 10))
            Text(feature.rawValue)
                .font(.system(size: 10))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(featureBackground)
        .foregroundColor(.secondary)
        .cornerRadius(6)
    }

    private var featureBackground: Color {
        #if os(iOS)
        return Color(.systemGray6)
        #else
        return Color(nsColor: .controlBackgroundColor)
        #endif
    }
}

struct AvailabilityBadge: View {
    let status: ParkingAvailability

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(status.rawValue)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .foregroundColor(color)
        .cornerRadius(6)
    }

    private var color: Color {
        switch status {
        case .available: return .green
        case .limited: return .orange
        case .full: return .red
        }
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Searching for parking...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
}

struct ErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("Error")
                .font(.title2)
                .fontWeight(.semibold)

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                retry()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - View Model

@MainActor
class ParkingSelectionViewModel: ObservableObject {
    @Published var parkingSpots: [ParkingSpot] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var sortOption: SortOption = .distance {
        didSet {
            sortParkingSpots()
        }
    }

    private let parkingService = ParkMobileService.shared

    enum SortOption {
        case distance
        case price
        case walkingTime
    }

    func searchParking(stadium: Stadium, startTime: Date, endTime: Date) async {
        isLoading = true
        errorMessage = nil

        do {
            let spots = try await parkingService.searchParkingNearStadium(
                stadium: stadium,
                startTime: startTime,
                endTime: endTime
            )
            parkingSpots = spots
            sortParkingSpots()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func sortParkingSpots() {
        switch sortOption {
        case .distance:
            parkingSpots.sort { $0.distanceToStadium < $1.distanceToStadium }
        case .price:
            parkingSpots.sort { $0.totalPrice < $1.totalPrice }
        case .walkingTime:
            parkingSpots.sort { $0.walkingTimeToStadium < $1.walkingTimeToStadium }
        }
    }
}

// MARK: - Preview

#Preview {
    ParkingSelectionView(
        stadium: Stadium.knownVenues[0],
        startTime: Date(),
        endTime: Date().addingTimeInterval(10800)
    ) { spot in
        print("Selected: \(spot.name)")
    }
}
