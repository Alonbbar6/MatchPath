import SwiftUI

/// SwiftUI picker for selecting a navigation app
struct NavigationAppPickerView: View {
    let origin: Coordinate?
    let destination: Coordinate
    let destinationName: String
    @Environment(\.dismiss) private var dismiss

    @State private var availableApps: [NavigationService.NavigationApp] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)

                    Text("Start Navigation")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Navigate to \(destinationName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
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
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                #elseif os(macOS)
                // Use a macOS-supported placement
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                #endif
            }
            .onAppear {
                availableApps = NavigationService.shared.getAvailableNavigationApps()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "map.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Navigation Apps Found")
                .font(.headline)

            Text("Please install Apple Maps, Google Maps, or Waze")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var appsList: some View {
        List {
            ForEach(availableApps, id: \.self) { app in
                Button {
                    NavigationService.shared.startNavigation(
                        using: app,
                        from: origin,
                        to: destination,
                        destinationName: destinationName
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

                            Text(appDescription(for: app))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .listStyle(.plain)
    }

    private func appColor(for app: NavigationService.NavigationApp) -> Color {
        switch app {
        case .appleMaps:
            return .blue
        case .googleMaps:
            return .green
        case .waze:
            return .cyan
        }
    }

    private func appDescription(for app: NavigationService.NavigationApp) -> String {
        switch app {
        case .appleMaps:
            return "Built-in iOS navigation"
        case .googleMaps:
            return "Popular navigation with traffic"
        case .waze:
            return "Community-based navigation"
        }
    }
}

#Preview {
    NavigationAppPickerView(
        origin: Coordinate(latitude: 25.7700, longitude: -80.1900),
        destination: Coordinate(latitude: 25.7617, longitude: -80.1918),
        destinationName: "Hard Rock Stadium"
    )
}
