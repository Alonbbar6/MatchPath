import SwiftUI

// MARK: - Settings View

struct AppSettingsView: View {
    @ObservedObject private var layoutPreference = LayoutPreferenceService.shared

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Layout Style")) {
                    Picker("Layout", selection: $layoutPreference.layoutStyle) {
                        ForEach(LayoutPreferenceService.LayoutStyle.allCases, id: \.self) { style in
                            HStack {
                                Image(systemName: style.icon)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(style.displayName)
                                    Text(style.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .tag(style)
                        }
                    }
                    .pickerStyle(.inline)

                    Text("Choose how you want to navigate the app")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Build")
                        Spacer()
                        Text("1")
                            .foregroundColor(.secondary)
                    }
                }

                Section(header: Text("Legal")) {
                    Text("This app is not affiliated with, endorsed by, or connected to any sports leagues, teams, or event organizers. All venue and event data is provided for informational purposes only.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("Support")) {
                    Link("Help Center", destination: URL(string: "https://alonbbar6.github.io/MatchPath/")!)
                    Link("Contact Us", destination: URL(string: "mailto:alonbbar@gmail.com")!)
                    Link("Privacy Policy", destination: URL(string: "https://alonbbar6.github.io/MatchPath/privacy.html")!)
                }

                Section(header: Text("Features")) {
                    HStack {
                        Image(systemName: "map.fill")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text("Google Maps Integration")
                                .font(.headline)
                            Text("Real-time traffic & routing")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack {
                        Image(systemName: "person.3.fill")
                            .foregroundColor(.orange)
                        VStack(alignment: .leading) {
                            Text("Crowd Intelligence")
                                .font(.headline)
                            Text("Avoid peak times & congestion")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.red)
                        VStack(alignment: .leading) {
                            Text("Smart Notifications")
                                .font(.headline)
                            Text("Never miss departure time")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Help & Info")
        }
        #if os(iOS)
        .navigationViewStyle(.stack)
        #endif
    }
}
