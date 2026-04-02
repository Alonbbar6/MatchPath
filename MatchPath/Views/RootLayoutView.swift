import SwiftUI

/// Root view that switches between layout styles based on user preference
struct RootLayoutView: View {
    @StateObject private var layoutPreference = LayoutPreferenceService.shared

    var body: some View {
        Group {
            switch layoutPreference.layoutStyle {
            case .unified:
                ContentView() // Original unified layout
            case .modular:
                ModularContentView() // New feature-separated layout
            }
        }
        .animation(.easeInOut(duration: 0.3), value: layoutPreference.layoutStyle)
    }
}

#Preview {
    RootLayoutView()
}
