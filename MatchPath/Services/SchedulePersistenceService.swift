import Foundation
import Combine

/// Service for persisting and retrieving game schedules
/// Uses UserDefaults for simple, reliable storage
/// All users have unlimited schedules
class SchedulePersistenceService: ObservableObject {
    static let shared = SchedulePersistenceService()

    // MARK: - Published Properties

    @Published private(set) var savedSchedules: [GameSchedule] = []

    // MARK: - Private Properties

    private let userDefaults = UserDefaults.standard
    private let schedulesKey = "saved_game_schedules"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let premiumManager = PremiumManager.shared

    // MARK: - Initialization

    private init() {
        // Configure date encoding/decoding
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601

        // Load saved schedules on init
        loadSchedules()
    }

    // MARK: - Public Methods

    /// Check if user can create a new schedule
    /// FREE users: 1 schedule limit
    /// PREMIUM users: Unlimited
    /// - Returns: True if user can create a new schedule
    func canCreateNewSchedule() -> Bool {
        return premiumManager.canCreateSchedule(currentCount: savedSchedules.count)
    }

    /// Get remaining free schedules for free users
    /// - Returns: Number of remaining free schedules (or Int.max for premium)
    func remainingFreeSchedules() -> Int {
        return premiumManager.remainingFreeSchedules(currentCount: savedSchedules.count)
    }

    /// Save a new schedule
    /// - Parameter schedule: The schedule to save
    /// - Returns: Success or failure (false if limit reached for free users)
    @discardableResult
    func saveSchedule(_ schedule: GameSchedule) -> Bool {
        print("💾 SchedulePersistence: Saving schedule \(schedule.id)")

        // Check if schedule already exists
        if let index = savedSchedules.firstIndex(where: { $0.id == schedule.id }) {
            // Update existing schedule (always allowed)
            print("📝 Updating existing schedule at index \(index)")
            savedSchedules[index] = schedule
        } else {
            // Check if user can create a new schedule (FREE limit check)
            if !canCreateNewSchedule() {
                print("⚠️ Cannot create new schedule: FREE tier limit reached (\(PremiumManager.FREE_SCHEDULE_LIMIT) schedule max)")
                print("💎 Upgrade to Premium for unlimited schedules")
                return false
            }

            // Add new schedule
            print("➕ Adding new schedule. Total will be: \(savedSchedules.count + 1)")
            savedSchedules.append(schedule)
        }

        print("📊 Current saved schedules count: \(savedSchedules.count)")

        // Persist to UserDefaults
        let success = persistSchedules()
        print(success ? "✅ Persist to UserDefaults succeeded" : "❌ Persist to UserDefaults failed")
        return success
    }

    /// Delete a schedule
    /// - Parameter scheduleId: The ID of the schedule to delete
    /// - Returns: Success or failure
    @discardableResult
    func deleteSchedule(_ scheduleId: String) -> Bool {
        print("🗑️ SchedulePersistence: Deleting schedule \(scheduleId)")

        savedSchedules.removeAll { $0.id == scheduleId }

        // Cancel notifications for this schedule
        Task {
            await NotificationService.shared.cancelNotifications(for: scheduleId)
        }

        return persistSchedules()
    }

    /// Get a specific schedule by ID
    /// - Parameter id: The schedule ID
    /// - Returns: The schedule if found
    func getSchedule(by id: String) -> GameSchedule? {
        return savedSchedules.first { $0.id == id }
    }

    /// Get all schedules for a specific game
    /// - Parameter gameId: The game ID
    /// - Returns: Array of schedules for that game
    func getSchedules(for gameId: String) -> [GameSchedule] {
        return savedSchedules.filter { $0.game.id == gameId }
    }

    /// Get active schedules (today's games)
    var activeSchedules: [GameSchedule] {
        return savedSchedules.filter { $0.isActive }
    }

    /// Get upcoming schedules (future games)
    var upcomingSchedules: [GameSchedule] {
        let now = Date()
        return savedSchedules.filter { $0.game.kickoffTime > now }
            .sorted { $0.game.kickoffTime < $1.game.kickoffTime }
    }

    /// Get past schedules
    var pastSchedules: [GameSchedule] {
        let now = Date()
        return savedSchedules.filter { $0.game.kickoffTime < now }
            .sorted { $0.game.kickoffTime > $1.game.kickoffTime }
    }

    /// Clear all saved schedules
    @discardableResult
    func clearAllSchedules() -> Bool {
        print("🗑️ SchedulePersistence: Clearing all schedules")
        savedSchedules.removeAll()
        return persistSchedules()
    }

    // MARK: - Private Methods

    /// Load schedules from UserDefaults
    private func loadSchedules() {
        guard let data = userDefaults.data(forKey: schedulesKey) else {
            print("💾 SchedulePersistence: No saved schedules found")
            savedSchedules = []
            return
        }

        do {
            let schedules = try decoder.decode([GameSchedule].self, from: data)
            savedSchedules = schedules
            print("💾 SchedulePersistence: Loaded \(schedules.count) schedule(s)")
        } catch {
            print("❌ SchedulePersistence: Failed to decode schedules - \(error.localizedDescription)")
            savedSchedules = []
        }
    }

    /// Persist schedules to UserDefaults
    private func persistSchedules() -> Bool {
        do {
            let data = try encoder.encode(savedSchedules)
            userDefaults.set(data, forKey: schedulesKey)
            print("💾 SchedulePersistence: Persisted \(savedSchedules.count) schedule(s)")
            return true
        } catch {
            print("❌ SchedulePersistence: Failed to encode schedules - \(error.localizedDescription)")
            return false
        }
    }
}
