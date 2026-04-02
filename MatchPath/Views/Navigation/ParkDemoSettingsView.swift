import SwiftUI
import CoreLocation

struct ParkDemoSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var parkDemoService = ParkDemoService.shared
    @ObservedObject private var locationManager = LocationManager.shared
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Enable Park Demo Mode", isOn: Binding(
                        get: { parkDemoService.isEnabled },
                        set: { newValue in
                            if newValue {
                                // Set park center to current location when enabling
                                if let location = locationManager.currentLocation {
                                    parkDemoService.activate(
                                        parkCenter: location.coordinate,
                                        stadiumId: parkDemoService.selectedStadiumId,
                                        scale: parkDemoService.scaleFactor
                                    )
                                } else {
                                    parkDemoService.isEnabled = true
                                }
                            } else {
                                parkDemoService.deactivate()
                            }
                        }
                    ))
                        .tint(.green)

                    if parkDemoService.isEnabled {
                        Button {
                            if let location = locationManager.currentLocation {
                                parkDemoService.parkCenter = location.coordinate
                            }
                        } label: {
                            Label("Set Current Location as Center", systemImage: "mappin.and.ellipse")
                        }

                        if let center = parkDemoService.parkCenter {
                            HStack {
                                Text("Park Center")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(String(format: "%.6f, %.6f", center.latitude, center.longitude))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Demo Mode")
                } footer: {
                    Text("Stand at the center of a park, then enable demo mode. Your current GPS location becomes the stadium center. Walk around to test compass navigation.")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("GPS Status")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if let location = locationManager.currentLocation {
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.green)
                                Text("Active")
                                    .foregroundColor(.green)
                                Spacer()
                                Text(String(format: "%.6f, %.6f", 
                                          location.coordinate.latitude,
                                          location.coordinate.longitude))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            HStack {
                                Image(systemName: "location.slash")
                                    .foregroundColor(.orange)
                                Text("No location")
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Heading")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Image(systemName: "safari")
                                .foregroundColor(.blue)
                            Text(String(format: "%.1f°", locationManager.currentHeading))
                                .font(.body)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Location Info")
                }
                
                Section {
                    HStack {
                        Text("Scale Factor")
                        Spacer()
                        Text(String(format: "%.1fx", parkDemoService.scaleFactor))
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(value: $parkDemoService.scaleFactor, in: 1...20, step: 0.5)
                        .tint(.blue)
                } header: {
                    Text("Sensitivity")
                } footer: {
                    Text("Higher values make small GPS movements translate to larger stadium distances. Useful for testing in confined spaces.")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Walk around", systemImage: "figure.walk")
                        Text("The compass arrow will rotate as you change direction")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Divider()
                        
                        Label("Move closer", systemImage: "arrow.forward")
                        Text("Distance will decrease as you walk in the target direction")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Divider()
                        
                        Label("Adjust scale", systemImage: "slider.horizontal.3")
                        Text("Increase scale factor if movements seem too small")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("How to Use")
                }
            }
            .navigationTitle("Park Demo Settings")
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
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #endif
            }
            .onAppear {
                locationManager.requestPermission()
                locationManager.startTracking()
            }
        }
    }
}

#Preview {
    ParkDemoSettingsView()
}
