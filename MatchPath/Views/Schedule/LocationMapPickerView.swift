import SwiftUI
import MapKit

struct LocationMapPickerView: View {
    @Binding var locationName: String
    @Binding var locationAddress: String
    let onLocationSelected: (Coordinate) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 25.7617, longitude: -80.1918), // Default to Miami
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @StateObject private var locationManager = LocationManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                // Map using region-based initializer
                Map(coordinateRegion: $region, interactionModes: .all, showsUserLocation: true, userTrackingMode: .none, annotationItems: selectedCoordinate.map { [MapPin(coordinate: $0)] } ?? []) { pin in
                    // Show a marker at the selected coordinate, if any
                    MapMarker(coordinate: pin.coordinate, tint: .red)
                }
                .mapStyle(.standard)
                .allowsHitTesting(true)
                .overlay(alignment: .topLeading) {
                    // Show user location control if you want (optional)
                    EmptyView()
                }
                .overlay(alignment: .bottomTrailing) {
                    EmptyView()
                }
                .overlay(alignment: .center) {
                    // Crosshair in center
                    Image(systemName: "scope")
                        .font(.system(size: 40))
                        .foregroundColor(.red)
                        .allowsHitTesting(false)
                }

                // Instructions and actions overlay
                VStack {
                    Spacer()

                    VStack(spacing: 16) {
                        Text("Move map to select your location")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(12)

                        Text("📍 \(String(format: "%.4f", region.center.latitude)), \(String(format: "%.4f", region.center.longitude))")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(8)

                        // Action buttons
                        HStack(spacing: 16) {
                            Button {
                                centerOnUserLocation()
                            } label: {
                                HStack {
                                    Image(systemName: "location.fill")
                                    Text("My Location")
                                }
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }

                            Button {
                                confirmLocation()
                            } label: {
                                HStack {
                                    Image(systemName: "checkmark")
                                    Text("Confirm Location")
                                }
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Select Location")
            #if os(iOS) || os(tvOS) || os(visionOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS) || os(tvOS) || os(visionOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                #endif
            }
            .onAppear {
                selectedCoordinate = region.center
                centerOnUserLocation()
            }
            // Keep selected pin aligned with the map center as the user pans/zooms
            .onChange(of: region.center.latitude) { _ in
                selectedCoordinate = region.center
            }
            .onChange(of: region.center.longitude) { _ in
                selectedCoordinate = region.center
            }
        }
    }

    private func centerOnUserLocation() {
        locationManager.requestPermission()
        locationManager.startTracking()

        if let location = locationManager.currentLocation {
            withAnimation {
                region.center = location.coordinate
            }
        }
    }

    private func confirmLocation() {
        // Update selected coordinate to current map center
        selectedCoordinate = region.center

        let coordinate = Coordinate(
            latitude: region.center.latitude,
            longitude: region.center.longitude
        )
        onLocationSelected(coordinate)
        dismiss()
    }
}

private struct MapPin: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

#Preview {
    LocationMapPickerView(
        locationName: .constant(""),
        locationAddress: .constant(""),
        onLocationSelected: { _ in }
    )
}
