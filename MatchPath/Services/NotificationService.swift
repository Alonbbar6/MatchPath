import Foundation
import UserNotifications
import Combine

/// Service for managing local push notifications
/// Sends reminders for schedule steps and game-day alerts
@MainActor
class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()

    // MARK: - Published Properties

    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published private(set) var notificationsEnabled = false

    // MARK: - Private Properties

    private let notificationCenter = UNUserNotificationCenter.current()

    // MARK: - Initialization

    private override init() {
        super.init()
        notificationCenter.delegate = self
        // Check authorization status asynchronously
        Task {
            await checkAuthorizationStatus()
        }
    }

    // MARK: - Permission Management

    /// Request notification permission from user
    func requestPermission() async -> Bool {
        print("📢 NotificationService: Requesting notification permission")

        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])

            await MainActor.run {
                notificationsEnabled = granted
                print(granted ? "✅ Notification permission granted" : "❌ Notification permission denied")
            }

            // Update authorization status
            await checkAuthorizationStatus()

            return granted
        } catch {
            print("❌ NotificationService: Permission request failed - \(error.localizedDescription)")
            return false
        }
    }

    /// Check current authorization status
    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()

        await MainActor.run {
            authorizationStatus = settings.authorizationStatus
            notificationsEnabled = settings.authorizationStatus == .authorized
            print("📢 NotificationService: Authorization status - \(settings.authorizationStatus.rawValue)")
        }
    }

    // MARK: - Schedule Notifications

    /// Schedule all notifications for a game schedule
    /// - Parameter schedule: The game schedule to create notifications for
    func scheduleNotifications(for schedule: GameSchedule) async {
        guard notificationsEnabled else {
            print("⚠️ NotificationService: Cannot schedule - notifications not enabled")
            return
        }

        print("📢 NotificationService: Scheduling notifications for schedule \(schedule.id)")

        // Cancel any existing notifications for this schedule
        await cancelNotifications(for: schedule.id)

        // Create notifications for each schedule step
        for step in schedule.scheduleSteps {
            await scheduleNotification(for: step, schedule: schedule)
        }

        // Add a special notification 1 hour before kickoff
        await scheduleKickoffReminder(for: schedule)

        print("✅ NotificationService: Scheduled \(schedule.scheduleSteps.count + 1) notifications")
    }

    /// Schedule a notification for a specific schedule step
    private func scheduleNotification(for step: ScheduleStep, schedule: GameSchedule) async {
        // Don't schedule notifications for steps in the past
        guard step.scheduledTime > Date() else {
            print("⏭️ Skipping past step: \(step.title)")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = step.title
        content.body = step.description
        content.sound = .default
        content.badge = 1

        // Add custom data for handling tap
        content.userInfo = [
            "scheduleId": schedule.id,
            "stepId": step.id,
            "stepType": step.stepType.rawValue
        ]

        // Add category for actions
        content.categoryIdentifier = "SCHEDULE_STEP"

        // Create time-based trigger
        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: step.scheduledTime
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        // Create request
        let identifier = "schedule-\(schedule.id)-step-\(step.id)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await notificationCenter.add(request)
            print("✅ Scheduled notification: \(step.title) at \(step.formattedTime)")
        } catch {
            print("❌ Failed to schedule notification: \(error.localizedDescription)")
        }
    }

    /// Schedule a reminder 1 hour before kickoff
    private func scheduleKickoffReminder(for schedule: GameSchedule) async {
        let reminderTime = schedule.game.kickoffTime.addingTimeInterval(-3600) // 1 hour before

        guard reminderTime > Date() else {
            print("⏭️ Skipping kickoff reminder - time has passed")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "⚽ Game Starting Soon!"
        content.body = "\(schedule.game.displayName) kicks off in 1 hour at \(schedule.game.stadium.name)"
        content.sound = .default
        content.badge = 1

        content.userInfo = [
            "scheduleId": schedule.id,
            "type": "kickoff_reminder"
        ]

        content.categoryIdentifier = "KICKOFF_REMINDER"

        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminderTime
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let identifier = "schedule-\(schedule.id)-kickoff"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await notificationCenter.add(request)
            print("✅ Scheduled kickoff reminder for \(schedule.game.displayName)")
        } catch {
            print("❌ Failed to schedule kickoff reminder: \(error.localizedDescription)")
        }
    }

    // MARK: - Cancel Notifications

    /// Cancel all notifications for a specific schedule
    /// - Parameter scheduleId: The schedule ID
    func cancelNotifications(for scheduleId: String) async {
        let allPending = await notificationCenter.pendingNotificationRequests()

        let identifiersToCancel = allPending
            .filter { $0.identifier.contains("schedule-\(scheduleId)") }
            .map { $0.identifier }

        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiersToCancel)
        print("🗑️ Cancelled \(identifiersToCancel.count) notifications for schedule \(scheduleId)")
    }

    /// Cancel all pending notifications
    func cancelAllNotifications() async {
        notificationCenter.removeAllPendingNotificationRequests()
        print("🗑️ Cancelled all pending notifications")
    }

    // MARK: - Query Notifications

    /// Get all pending notification requests
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await notificationCenter.pendingNotificationRequests()
    }

    /// Get count of pending notifications
    func getPendingNotificationCount() async -> Int {
        let requests = await getPendingNotifications()
        return requests.count
    }

    // MARK: - Notification Categories

    /// Register notification categories with actions
    func registerNotificationCategories() {
        // Schedule step category
        let viewScheduleAction = UNNotificationAction(
            identifier: "VIEW_SCHEDULE",
            title: "View Schedule",
            options: [.foreground]
        )

        let markCompleteAction = UNNotificationAction(
            identifier: "MARK_COMPLETE",
            title: "Mark Complete",
            options: []
        )

        let scheduleStepCategory = UNNotificationCategory(
            identifier: "SCHEDULE_STEP",
            actions: [viewScheduleAction, markCompleteAction],
            intentIdentifiers: [],
            options: []
        )

        // Kickoff reminder category
        let viewGameAction = UNNotificationAction(
            identifier: "VIEW_GAME",
            title: "View Details",
            options: [.foreground]
        )

        let kickoffCategory = UNNotificationCategory(
            identifier: "KICKOFF_REMINDER",
            actions: [viewGameAction],
            intentIdentifiers: [],
            options: []
        )

        notificationCenter.setNotificationCategories([scheduleStepCategory, kickoffCategory])
        print("✅ Registered notification categories")
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    /// Handle notification when app is in foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    /// Handle notification tap
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        print("📢 Notification tapped: \(response.actionIdentifier)")

        // Handle different actions
        switch response.actionIdentifier {
        case "VIEW_SCHEDULE", "VIEW_GAME":
            // TODO: Navigate to schedule detail view
            if let scheduleId = userInfo["scheduleId"] as? String {
                print("📍 Navigate to schedule: \(scheduleId)")
                // This would be handled by the app's deep linking system
            }

        case "MARK_COMPLETE":
            if let stepId = userInfo["stepId"] as? String {
                print("✅ Mark step complete: \(stepId)")
                // TODO: Update step completion status
            }

        case UNNotificationDefaultActionIdentifier:
            // User tapped notification body
            if let scheduleId = userInfo["scheduleId"] as? String {
                print("📍 Open schedule: \(scheduleId)")
            }

        default:
            break
        }

        completionHandler()
    }
}
