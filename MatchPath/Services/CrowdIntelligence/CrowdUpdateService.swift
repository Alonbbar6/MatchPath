import Foundation
import Combine
import UserNotifications

/// Service for managing real-time crowd updates on game day
/// Provides background refresh, push notifications, and live UI updates
class CrowdUpdateService: ObservableObject {
    static let shared = CrowdUpdateService()

    // MARK: - Published Properties

    /// Current crowd forecast - UI subscribes to this for live updates
    @Published private(set) var currentForecast: StadiumCrowdForecast?

    /// Last update time
    @Published private(set) var lastUpdateTime: Date?

    /// Whether updates are currently active
    @Published private(set) var isUpdating: Bool = false

    // MARK: - Private Properties

    private var updateTimer: Timer?
    private let crowdService = CrowdIntelligenceService.shared
    private let notificationService = NotificationService.shared

    /// How often to refresh crowd data (in seconds)
    private let updateInterval: TimeInterval = 5 * 60 // 5 minutes

    /// Threshold for "significant" crowd level change (triggers notification)
    private let significantChangeThreshold: Int = 1 // 1 level change (e.g., moderate -> crowded)

    private init() {}

    // MARK: - Public Methods

    /// Start real-time updates for a schedule
    /// - Parameter schedule: The schedule to monitor
    func startUpdates(for schedule: GameSchedule) {
        print("🔄 CrowdUpdateService: Starting real-time updates for schedule \(schedule.id)")

        // Stop any existing updates
        stopUpdates()

        // Initial fetch
        Task {
            await refreshCrowdData(for: schedule)
        }

        // Only start timer if it's game day and before the game ends
        let now = Date()
        let gameTime = schedule.game.kickoffTime
        let gameEndTime = gameTime.addingTimeInterval(2.5 * 3600) // 2.5 hours after kickoff

        guard Calendar.current.isDate(gameTime, inSameDayAs: now),
              now < gameEndTime else {
            print("⏸️ CrowdUpdateService: Not game day or game ended - skipping timer")
            return
        }

        // Start periodic updates
        isUpdating = true
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task {
                await self.refreshCrowdData(for: schedule)
            }
        }

        print("✅ CrowdUpdateService: Timer started with \(Int(updateInterval/60)) minute interval")
    }

    /// Stop real-time updates
    func stopUpdates() {
        print("⏹️ CrowdUpdateService: Stopping real-time updates")
        updateTimer?.invalidate()
        updateTimer = nil
        isUpdating = false
    }

    /// Manually refresh crowd data
    /// - Parameter schedule: The schedule to refresh
    func manualRefresh(for schedule: GameSchedule) async {
        print("🔄 CrowdUpdateService: Manual refresh requested")
        await refreshCrowdData(for: schedule)
    }

    // MARK: - Private Methods

    /// Refresh crowd data from the crowd intelligence service
    private func refreshCrowdData(for schedule: GameSchedule) async {
        let stadium = schedule.game.stadium
        let kickoffTime = schedule.game.kickoffTime

        print("📊 CrowdUpdateService: Fetching crowd forecast for \(stadium.name)")

        // Get updated forecast
        let newForecast = await crowdService.getStadiumCrowdForecast(
            for: stadium,
            at: kickoffTime
        )

        // Check for significant changes
        if let oldForecast = currentForecast {
            await checkForSignificantChanges(
                old: oldForecast,
                new: newForecast,
                schedule: schedule
            )
        }

        // Update published properties on main thread
        await MainActor.run {
            self.currentForecast = newForecast
            self.lastUpdateTime = Date()
            print("✅ CrowdUpdateService: Forecast updated at \(Date())")
            print("   Overall crowd level: \(newForecast.overallUICrowdLevel.rawValue)")
            print("   Estimated wait: \(newForecast.estimatedWaitTimeMinutes) min")
        }
    }

    /// Check if crowd levels have changed significantly and send notifications
    private func checkForSignificantChanges(
        old: StadiumCrowdForecast,
        new: StadiumCrowdForecast,
        schedule: GameSchedule
    ) async {
        // Compare overall crowd intensity
        let oldLevel = old.overallCrowdIntensity.rawValue
        let newLevel = new.overallCrowdIntensity.rawValue
        let levelChange = abs(newLevel - oldLevel)

        guard levelChange >= significantChangeThreshold else {
            print("ℹ️ CrowdUpdateService: No significant crowd change (change: \(levelChange))")
            return
        }

        print("⚠️ CrowdUpdateService: Significant crowd change detected!")
        print("   Old: \(old.overallCrowdIntensity.description)")
        print("   New: \(new.overallCrowdIntensity.description)")

        // Send notification about the change
        let notification = CrowdChangeNotification(
            scheduleId: schedule.id,
            stadium: schedule.game.stadium.name,
            oldLevel: old.overallUICrowdLevel,
            newLevel: new.overallUICrowdLevel,
            waitTime: new.estimatedWaitTimeMinutes,
            recommendedGate: new.recommendedGates.first?.name ?? "Gate A"
        )

        await sendCrowdChangeNotification(notification)
    }

    /// Send a push notification about crowd level changes
    private func sendCrowdChangeNotification(_ notification: CrowdChangeNotification) async {
        let content = UNMutableNotificationContent()

        // Customize based on severity
        if notification.newLevel == .avoid {
            content.title = "🚨 High Crowds at \(notification.stadium)"
            content.body = "Crowd levels are now \(notification.newLevel.rawValue). Expect \(notification.waitTime) min wait. Consider heading out early!"
            content.sound = .defaultCritical
        } else if notification.newLevel == .crowded {
            content.title = "🟠 Crowds Building at \(notification.stadium)"
            content.body = "Crowd levels increased to \(notification.newLevel.rawValue). Estimated wait: \(notification.waitTime) min."
            content.sound = .default
        } else {
            content.title = "🟢 Good News - Lower Crowds!"
            content.body = "Crowd levels improved to \(notification.newLevel.rawValue) at \(notification.stadium)."
            content.sound = .default
        }

        // Add action to view schedule
        content.categoryIdentifier = "CROWD_UPDATE"
        content.userInfo = ["scheduleId": notification.scheduleId]

        // Send immediately
        let request = UNNotificationRequest(
            identifier: "crowd-update-\(notification.scheduleId)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil // Send immediately
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            print("✅ CrowdUpdateService: Notification sent")
        } catch {
            print("❌ CrowdUpdateService: Failed to send notification - \(error)")
        }
    }

    /// Get time until next update
    var timeUntilNextUpdate: String {
        guard let lastUpdate = lastUpdateTime else {
            return "Never updated"
        }

        let nextUpdateTime = lastUpdate.addingTimeInterval(updateInterval)
        let timeRemaining = nextUpdateTime.timeIntervalSinceNow

        if timeRemaining <= 0 {
            return "Updating soon..."
        }

        let minutes = Int(timeRemaining / 60)
        return "\(minutes) min"
    }
}

// MARK: - Models

struct CrowdChangeNotification {
    let scheduleId: String
    let stadium: String
    let oldLevel: CrowdLevel
    let newLevel: CrowdLevel
    let waitTime: Int
    let recommendedGate: String
}
