import SwiftUI
import UserNotifications

@main
struct MatchPathApp: App {
    @StateObject private var notificationService = NotificationService.shared

    init() {
        // Register notification categories on app launch
        NotificationService.shared.registerNotificationCategories()
    }

    var body: some Scene {
        WindowGroup {
            RootLayoutView()
                .onAppear {
                    // Request notification permission when app first appears
                    Task {
                        if notificationService.authorizationStatus == .notDetermined {
                            _ = await notificationService.requestPermission()
                        } else {
                            await notificationService.checkAuthorizationStatus()
                        }
                    }
                }
                .environmentObject(notificationService)
        }
    }
}
