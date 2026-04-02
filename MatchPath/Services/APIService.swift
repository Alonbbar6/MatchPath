import Foundation
import Combine

protocol APIServiceProtocol {
    func fetchMatches(for league: League?) -> AnyPublisher<[Match], Error>
    func fetchMatches(for league: League?, status: MatchStatusFilter?) -> AnyPublisher<[Match], Error>
    func fetchTeams() -> AnyPublisher<[Team], Error>
    func fetchLeagues() -> AnyPublisher<[League], Error>
    func fetchStandings(for league: League) -> AnyPublisher<[Standing], Error>
    func fetchMatchDetails(matchId: Int) -> AnyPublisher<Match, Error>
    func fetchPlayers(for team: Team) -> AnyPublisher<[Player], Error>
    func toggleFavorite(team: Team) -> AnyPublisher<Team, Error>
    func getFavoriteTeams() -> AnyPublisher<[Team], Error>
    func fetchUserStats() -> AnyPublisher<UserStats, Error>
    func fetchAnalytics(dateRange: DateRange) -> AnyPublisher<AnalyticsData, Error>
    func fetchSystemStatus() -> AnyPublisher<SystemStatus, Error>
    func toggleLike(matchId: Int) -> AnyPublisher<Bool, Error>
    func toggleFavorite(matchId: Int) -> AnyPublisher<Bool, Error>
    func rateMatch(matchId: Int, rating: Double) -> AnyPublisher<Bool, Error>
    func createReminder(reminder: Reminder) -> AnyPublisher<Bool, Error>
    func deleteReminder(reminderId: Int) -> AnyPublisher<Bool, Error>
}

// Status filter for API calls
enum MatchStatusFilter {
    case live
    case scheduled
    case finished
    
    var description: String {
        switch self {
        case .live: return "live"
        case .scheduled: return "scheduled"
        case .finished: return "finished"
        }
    }
}

class APIService: APIServiceProtocol {
    private let config = APIConfiguration.shared
    private let session = URLSession.shared
    private let matchService = MatchService.shared
    
    private var baseURL: String {
        return config.baseURL
    }
    
    private var headers: [String: String] {
        return config.headers
    }
    
    // MARK: - Matches
    
    /// Fetch matches without status filter (fetches all)
    func fetchMatches(for league: League?) -> AnyPublisher<[Match], Error> {
        return fetchMatches(for: league, status: nil)
    }
    
    /// Fetch matches with optional status filter
    func fetchMatches(for league: League?, status: MatchStatusFilter?) -> AnyPublisher<[Match], Error> {
        // Use real API via MatchService
        print("🔄 APIService: Fetching matches (league: \(league?.name ?? "all"), status: \(status?.description ?? "all"))")
        
        return Future { promise in
            Task {
                do {
                    var matches: [Match] = []
                    
                    // Determine which matches to fetch based on status
                    if let status = status {
                        switch status {
                        case .live:
                            matches = try await self.matchService.fetchLiveMatches()
                            print("✅ Fetched \(matches.count) live matches")
                        case .scheduled:
                            matches = try await self.matchService.fetchUpcomingMatches(days: 30)
                            print("✅ Fetched \(matches.count) upcoming matches")
                        case .finished:
                            let toDate = Date()
                            let fromDate = Calendar.current.date(byAdding: .day, value: -7, to: toDate)!
                            matches = try await self.matchService.fetchPastMatches(from: fromDate, to: toDate)
                            print("✅ Fetched \(matches.count) past matches")
                        }
                    } else {
                        // Fetch all: live + upcoming + past
                        async let live = self.matchService.fetchLiveMatches()
                        async let upcoming = self.matchService.fetchUpcomingMatches(days: 7)
                        let toDate = Date()
                        let fromDate = Calendar.current.date(byAdding: .day, value: -3, to: toDate)!
                        async let past = self.matchService.fetchPastMatches(from: fromDate, to: toDate)
                        
                        let (liveMatches, upcomingMatches, pastMatches) = try await (live, upcoming, past)
                        matches = liveMatches + upcomingMatches + pastMatches
                        print("✅ Fetched total: \(matches.count) matches (live: \(liveMatches.count), upcoming: \(upcomingMatches.count), past: \(pastMatches.count))")
                    }
                    
                    // Filter by league if specified
                    if let league = league {
                        matches = matches.filter { $0.league.id == league.id }
                        print("🔍 Filtered to \(matches.count) matches for league: \(league.name)")
                    }
                    
                    promise(.success(matches))
                } catch {
                    print("❌ Error fetching matches: \(error.localizedDescription)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func fetchMatchDetails(matchId: Int) -> AnyPublisher<Match, Error> {
        // Use real API to fetch match details
        return Future { promise in
            Task {
                do {
                    // Try to find in live matches first
                    let liveMatches = try await self.matchService.fetchLiveMatches()
                    if let match = liveMatches.first(where: { $0.id == matchId }) {
                        promise(.success(match))
                        return
                    }
                    
                    // Try upcoming matches
                    let upcomingMatches = try await self.matchService.fetchUpcomingMatches(days: 30)
                    if let match = upcomingMatches.first(where: { $0.id == matchId }) {
                        promise(.success(match))
                        return
                    }
                    
                    // Try past matches
                    let toDate = Date()
                    let fromDate = Calendar.current.date(byAdding: .day, value: -7, to: toDate)!
                    let pastMatches = try await self.matchService.fetchPastMatches(from: fromDate, to: toDate)
                    if let match = pastMatches.first(where: { $0.id == matchId }) {
                        promise(.success(match))
                        return
                    }
                    
                    // If not found, return error
                    promise(.failure(APIError.noData))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Teams and Leagues
    func fetchTeams() -> AnyPublisher<[Team], Error> {
        return Just(Team.mockTeams)
            .setFailureType(to: Error.self)
            .delay(for: .milliseconds(400), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func fetchLeagues() -> AnyPublisher<[League], Error> {
        return Just(League.mockLeagues)
            .setFailureType(to: Error.self)
            .delay(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func fetchStandings(for league: League) -> AnyPublisher<[Standing], Error> {
        return Just(Standing.mockStandings)
            .setFailureType(to: Error.self)
            .delay(for: .milliseconds(600), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func fetchPlayers(for team: Team) -> AnyPublisher<[Player], Error> {
        return Just(Player.mockPlayers)
            .setFailureType(to: Error.self)
            .delay(for: .milliseconds(400), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func toggleFavorite(team: Team) -> AnyPublisher<Team, Error> {
        // Create new team with toggled favorite status
        let updatedTeam = Team(
            id: team.id,
            name: team.name,
            shortName: team.shortName,
            logo: team.logo,
            stadium: team.stadium,
            city: team.city,
            country: team.country,
            founded: team.founded,
            colors: team.colors,
            isFavorite: !team.isFavorite
        )
        
        return Just(updatedTeam)
            .setFailureType(to: Error.self)
            .delay(for: .milliseconds(200), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func getFavoriteTeams() -> AnyPublisher<[Team], Error> {
        return Just(Team.mockTeams.filter { $0.isFavorite })
            .setFailureType(to: Error.self)
            .delay(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - User Actions
    func toggleLike(matchId: Int) -> AnyPublisher<Bool, Error> {
        return Just(true)
            .setFailureType(to: Error.self)
            .delay(for: .milliseconds(200), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func toggleFavorite(matchId: Int) -> AnyPublisher<Bool, Error> {
        return Just(true)
            .setFailureType(to: Error.self)
            .delay(for: .milliseconds(200), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func rateMatch(matchId: Int, rating: Double) -> AnyPublisher<Bool, Error> {
        return Just(true)
            .setFailureType(to: Error.self)
            .delay(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Reminders
    func createReminder(reminder: Reminder) -> AnyPublisher<Bool, Error> {
        return Just(true)
            .setFailureType(to: Error.self)
            .delay(for: .milliseconds(400), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func deleteReminder(reminderId: Int) -> AnyPublisher<Bool, Error> {
        return Just(true)
            .setFailureType(to: Error.self)
            .delay(for: .milliseconds(200), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Analytics
    func fetchUserStats() -> AnyPublisher<UserStats, Error> {
        return Just(User.mockUser.stats)
            .setFailureType(to: Error.self)
            .delay(for: .milliseconds(400), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func fetchAnalytics(dateRange: DateRange) -> AnyPublisher<AnalyticsData, Error> {
        return Just(AnalyticsData.mockAnalytics)
            .setFailureType(to: Error.self)
            .delay(for: .milliseconds(800), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - System
    func fetchSystemStatus() -> AnyPublisher<SystemStatus, Error> {
        return Just(SystemStatus.mockSystemStatus)
            .setFailureType(to: Error.self)
            .delay(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

// MARK: - Real API Implementation (for future use)
extension APIService {
    private func makeRequest<T: Codable>(endpoint: String, responseType: T.Type) -> AnyPublisher<T, Error> {
        guard let url = URL(string: baseURL + endpoint) else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        return session.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: responseType, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    private func makeRequest<T: Codable>(endpoint: String, parameters: [String: String], responseType: T.Type) -> AnyPublisher<T, Error> {
        guard var urlComponents = URLComponents(string: baseURL + endpoint) else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        urlComponents.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        
        guard let url = urlComponents.url else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        return session.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: responseType, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}