import Foundation
import Combine

/// Persists user-created sporting events locally
class UserEventStore: ObservableObject {
    static let shared = UserEventStore()

    private let storageKey = "UserSportingEvents"

    @Published private(set) var events: [SportingEvent] = []

    private init() {
        events = loadEvents()
    }

    // MARK: - CRUD

    /// Save a new event
    func addEvent(_ event: SportingEvent) {
        events.append(event)
        persistEvents()
    }

    /// Remove an event by ID
    func removeEvent(id: String) {
        events.removeAll { $0.id == id }
        persistEvents()
    }

    /// Get upcoming events sorted by date
    func upcomingEvents() -> [SportingEvent] {
        events
            .filter { $0.eventTime > Date() }
            .sorted { $0.eventTime < $1.eventTime }
    }

    // MARK: - Persistence

    private func loadEvents() -> [SportingEvent] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return [] }
        let decoder = JSONDecoder()
        return (try? decoder.decode([SportingEvent].self, from: data)) ?? []
    }

    private func persistEvents() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(events) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
