import Foundation
import Combine

protocol DataRepositoryProtocol {
    func fetchTeams() -> AnyPublisher<[Team], Error>
    func fetchLeagues() -> AnyPublisher<[League], Error>
    func fetchMatches(for league: League?) -> AnyPublisher<[Match], Error>
    func fetchStandings(for league: League) -> AnyPublisher<[Standing], Error>
    func fetchPlayers(for team: Team) -> AnyPublisher<[Player], Error>
    func toggleFavorite(team: Team) -> AnyPublisher<Team, Error>
    func getFavoriteTeams() -> AnyPublisher<[Team], Error>
}

class DataRepository: DataRepositoryProtocol {
    private let apiService: APIServiceProtocol
    private let cacheService: CacheServiceProtocol
    
    init(apiService: APIServiceProtocol = APIService(), cacheService: CacheServiceProtocol = CacheService()) {
        self.apiService = apiService
        self.cacheService = cacheService
    }
    
    func fetchTeams() -> AnyPublisher<[Team], Error> {
        // Check cache first
        if let cachedTeams = cacheService.getCachedTeams(), !cachedTeams.isEmpty {
            return Just(cachedTeams)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        // Fetch from API
        return apiService.fetchTeams()
            .handleEvents(receiveOutput: { [weak self] teams in
                self?.cacheService.cacheTeams(teams)
            })
            .eraseToAnyPublisher()
    }
    
    func fetchLeagues() -> AnyPublisher<[League], Error> {
        if let cachedLeagues = cacheService.getCachedLeagues(), !cachedLeagues.isEmpty {
            return Just(cachedLeagues)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        return apiService.fetchLeagues()
            .handleEvents(receiveOutput: { [weak self] leagues in
                self?.cacheService.cacheLeagues(leagues)
            })
            .eraseToAnyPublisher()
    }
    
    func fetchMatches(for league: League?) -> AnyPublisher<[Match], Error> {
        return apiService.fetchMatches(for: league)
            .handleEvents(receiveOutput: { [weak self] matches in
                self?.cacheService.cacheMatches(matches, for: league)
            })
            .eraseToAnyPublisher()
    }
    
    func fetchStandings(for league: League) -> AnyPublisher<[Standing], Error> {
        if let cachedStandings = cacheService.getCachedStandings(for: league) {
            return Just(cachedStandings)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        return apiService.fetchStandings(for: league)
            .handleEvents(receiveOutput: { [weak self] standings in
                self?.cacheService.cacheStandings(standings, for: league)
            })
            .eraseToAnyPublisher()
    }
    
    func fetchPlayers(for team: Team) -> AnyPublisher<[Player], Error> {
        return apiService.fetchPlayers(for: team)
    }
    
    func toggleFavorite(team: Team) -> AnyPublisher<Team, Error> {
        return apiService.toggleFavorite(team: team)
            .handleEvents(receiveOutput: { [weak self] updatedTeam in
                self?.cacheService.updateFavoriteTeam(updatedTeam)
            })
            .eraseToAnyPublisher()
    }
    
    func getFavoriteTeams() -> AnyPublisher<[Team], Error> {
        return apiService.getFavoriteTeams()
    }
}
