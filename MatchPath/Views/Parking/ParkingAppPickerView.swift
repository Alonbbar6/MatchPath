import SwiftUI

/// SwiftUI picker for selecting a parking reservation app
struct ParkingAppPickerView: View {
    let parkingSpot: ParkingSpot?
    let location: Coordinate?
    let locationName: String
    let startTime: Date
    let endTime: Date

    @Environment(\.dismiss) private var dismiss
    @State private var availableApps: [ParkingReservationService.ParkingApp] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "parkingsign.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)

                    Text("Reserve Parking")
                        .font(.title2)
                        .fontWeight(.bold)

                    if let spot = parkingSpot {
                        Text(spot.name)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    } else {
                        Text("Near \(locationName)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    // Time info
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Start")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(startTime.formatted(date: .omitted, time: .shortened))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }

                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("End")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(endTime.formatted(date: .omitted, time: .shortened))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.12))
                    .cornerRadius(12)
                }
                .padding(.top, 32)
                .padding(.bottom, 24)

                Divider()

                // App list
                if availableApps.isEmpty {
                    emptyState
                } else {
                    appsList
                }
            }
            #if os(iOS) || os(tvOS) || os(visionOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS) || os(tvOS) || os(visionOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                #elseif os(macOS)
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                #endif
            }
            .onAppear {
                availableApps = ParkingReservationService.shared.getAvailableParkingApps()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "parkingsign.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Parking Apps Found")
                .font(.headline)

            Text("Install ParkMobile, SpotHero, or ParkWhiz to reserve parking")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }

    private var appsList: some View {
        List {
            Section {
                ForEach(availableApps, id: \.self) { app in
                    Button {
                        ParkingReservationService.shared.openParkingApp(
                            app,
                            for: parkingSpot,
                            at: location,
                            locationName: locationName,
                            startTime: startTime,
                            endTime: endTime
                        )
                        dismiss()
                    } label: {
                        HStack(spacing: 16) {
                            // App icon
                            Circle()
                                .fill(appColor(for: app))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: app.icon)
                                        .font(.title3)
                                        .foregroundColor(.white)
                                )

                            // App name and description
                            VStack(alignment: .leading, spacing: 4) {
                                Text(app.rawValue)
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Text(app.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                }
            } header: {
                Text("Choose a parking app to complete your reservation")
                    .textCase(.none)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        #if os(iOS) || os(tvOS) || os(visionOS)
        .listStyle(.insetGrouped)
        #elseif os(macOS)
        .listStyle(.inset)
        #endif
    }

    private func appColor(for app: ParkingReservationService.ParkingApp) -> Color {
        switch app {
        case .parkMobile:
            return .orange
        case .spotHero:
            return .blue
        case .parkWhiz:
            return .purple
        }
    }
}

#Preview {
    ParkingAppPickerView(
        parkingSpot: ParkingSpot.mockSpots[0],
        location: nil,
        locationName: "Hard Rock Stadium",
        startTime: Date(),
        endTime: Date().addingTimeInterval(3600 * 4)
    )
}
