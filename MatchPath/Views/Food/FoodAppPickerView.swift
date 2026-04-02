import SwiftUI

/// SwiftUI picker for selecting a food ordering app
struct FoodAppPickerView: View {
    let stadium: Stadium
    let pickupTime: Date

    @Environment(\.dismiss) private var dismiss
    @State private var hasStadiumApp: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.red)

                    Text("Pre-Order Food")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("from \(stadium.name) vendors")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    // Pickup time info
                    HStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("Pickup: \(pickupTime.formatted(date: .omitted, time: .shortened))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(backgroundCardColor)
                    .cornerRadius(12)
                }
                .padding(.top, 32)
                .padding(.bottom, 24)

                Divider()

                // App list
                if hasStadiumApp {
                    appsList
                } else {
                    emptyState
                }
            }
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
            .onAppear {
                hasStadiumApp = FoodAppDeepLinkService.shared.stadiumAppAvailable(for: stadium)
            }
        }
    }

    // Cross-platform background color similar to systemGray6 on iOS
    private var backgroundCardColor: Color {
        #if canImport(UIKit)
        return Color(UIColor.systemGray6)
        #else
        return Color.secondary.opacity(0.12)
        #endif
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "building.2")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("Stadium App Not Installed")
                .font(.headline)

            if stadium.hasFoodOrderingWebsite {
                Text("The app isn't installed, but you can order on the website instead")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // Website button
                Button {
                    FoodAppDeepLinkService.shared.openStadiumWebsite(stadium: stadium)
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "safari")
                        Text("Order on Website")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            } else if let appName = stadium.foodOrderingAppName {
                Text("Download the \(appName) app from the App Store to pre-order food for this game")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else {
                Text("\(stadium.name) doesn't have a food ordering app yet. Check back later or order at the stadium.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding()
    }

    private var appsList: some View {
        List {
            // Stadium Official App
            Section {
                Button {
                    FoodAppDeepLinkService.shared.openStadiumApp(stadium: stadium, pickupTime: pickupTime)
                    dismiss()
                } label: {
                    HStack(spacing: 16) {
                        // Stadium app icon
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "building.2.fill")
                                    .font(.title3)
                                    .foregroundColor(.white)
                            )

                        // App name and description
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(stadium.foodOrderingAppName ?? stadium.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Text("OFFICIAL")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue)
                                    .cornerRadius(4)
                            }

                            Text("Order directly from stadium vendors")
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
            } header: {
                Text("Official Stadium Food Ordering")
                    .textCase(.none)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
            } footer: {
                Text("Pre-order food from \(stadium.name) concession stands. Pick up at express lanes and skip the lines!")
                    .textCase(.none)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Website Alternative (if available)
            if stadium.hasFoodOrderingWebsite {
                Section {
                    Button {
                        FoodAppDeepLinkService.shared.openStadiumWebsite(stadium: stadium)
                        dismiss()
                    } label: {
                        HStack(spacing: 16) {
                            // Website icon
                            Circle()
                                .fill(Color.green)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: "safari")
                                        .font(.title3)
                                        .foregroundColor(.white)
                                )

                            // Website description
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Order on Website")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Text("No app required - order in Safari")
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
                } header: {
                    Text("Alternative Option")
                        .textCase(.none)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .modifier(CrossPlatformListStyle())
    }
}

private struct CrossPlatformListStyle: ViewModifier {
    func body(content: Content) -> some View {
        #if os(iOS)
        content.listStyle(.insetGrouped)
        #else
        content.listStyle(.inset)
        #endif
    }
}

#Preview {
    FoodAppPickerView(
        stadium: Stadium.knownVenues[0],
        pickupTime: Date().addingTimeInterval(3600 * 2)
    )
}
