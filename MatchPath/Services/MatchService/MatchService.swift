import Foundation
import Combine

// MARK: - Match Service Protocol

protocol MatchServiceProtocol {
    func fetchLiveMatches() async throws -> [Match]
    func fetchMatchesByDate(_ date: Date) async throws -> [Match]
    func fetchUpcomingMatches(days: Int) async throws -> [Match]
    func fetchPastMatches(from: Date, to: Date) async throws -> [Match]
    func fetchMatchDetails(matchId: Int) async throws -> Match
    func refreshLiveMatches() async throws -> [Match]
    
    var liveMatchesPublisher: AnyPublisher<[Match], Never> { get }
}

// MARK: - Match Service Implementation

class MatchService: MatchServiceProtocol {
    static let shared = MatchService()
    
    private let apiService: NetworkAPIServiceProtocol
    private let cacheService: MatchCacheService
    private let liveMatchesSubject = CurrentValueSubject<[Match], Never>([])
    
    private var refreshTimer: Timer?
    private let refreshInterval: TimeInterval = 15 // 15 seconds for live matches
    private var isRefreshing = false
    
    init(apiService: NetworkAPIServiceProtocol = NetworkAPIService(),
         cacheService: MatchCacheService = MatchCacheService()) {
        self.apiService = apiService
        self.cacheService = cacheService
    }
    
    var liveMatchesPublisher: AnyPublisher<[Match], Never> {
        liveMatchesSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Live Matches
    
    func fetchLiveMatches() async throws -> [Match] {
        // Check cache first
        if let cached = cacheService.getCachedMatches(for: .live) {
            liveMatchesSubject.send(cached)
            return cached
        }
        
        let response: MatchAPIResponse = try await apiService.request(.liveMatches)
        let matches = response.response.map { $0.toMatch() }
        
        // Cache the results with 15 second TTL
        cacheService.cacheMatches(matches, for: .live, ttl: CachePolicy.liveMatches.ttl)
        liveMatchesSubject.send(matches)
        
        #if DEBUG
        print("⚽ Fetched \(matches.count) live matches")
        #endif
        
        return matches
    }
    
    func refreshLiveMatches() async throws -> [Match] {
        guard !isRefreshing else {
            return liveMatchesSubject.value
        }
        
        isRefreshing = true
        defer { isRefreshing = false }
        
        let response: MatchAPIResponse = try await apiService.request(.liveMatches)
        let matches = response.response.map { $0.toMatch() }
        
        // Update cache
        cacheService.cacheMatches(matches, for: .live, ttl: CachePolicy.liveMatches.ttl)
        liveMatchesSubject.send(matches)
        
        #if DEBUG
        print("🔄 Refreshed \(matches.count) live matches")
        #endif
        
        return matches
    }
    
    // MARK: - Matches by Date
    
    func fetchMatchesByDate(_ date: Date) async throws -> [Match] {
        let cacheKey = CacheKey.date(date)
        
        // Check cache
        if let cached = cacheService.getCachedMatches(for: cacheKey) {
            return cached
        }
        
        let response: MatchAPIResponse = try await apiService.request(.matchesByDate(date))
        let matches = response.response.map { $0.toMatch() }
        
        // Determine TTL based on date
        let isToday = Calendar.current.isDateInToday(date)
        let ttl = isToday ? CachePolicy.todayMatches.ttl : CachePolicy.pastMatches.ttl
        
        cacheService.cacheMatches(matches, for: cacheKey, ttl: ttl)
        
        #if DEBUG
        print("📅 Fetched \(matches.count) matches for date: \(date)")
        #endif
        
        return matches
    }
    
    // MARK: - Upcoming Matches
    
    func fetchUpcomingMatches(days: Int = 7) async throws -> [Match] {
        let today = Date()
        let future = Calendar.current.date(byAdding: .day, value: days, to: today) ?? today
        
        let cacheKey = CacheKey.dateRange(from: today, to: future)
        
        // Check cache
        if let cached = cacheService.getCachedMatches(for: cacheKey) {
            return cached
        }
        
        let response: MatchAPIResponse = try await apiService.request(
            .matchesByDateRange(from: today, to: future)
        )
        let matches = response.response.map { $0.toMatch() }
        
        // Cache for 1 hour
        cacheService.cacheMatches(matches, for: cacheKey, ttl: CachePolicy.upcomingMatches.ttl)
        
        #if DEBUG
        print("📆 Fetched \(matches.count) upcoming matches (next \(days) days)")
        #endif
        
        return matches
    }
    
    // MARK: - Past Matches
    
    func fetchPastMatches(from: Date, to: Date) async throws -> [Match] {
        let cacheKey = CacheKey.dateRange(from: from, to: to)
        
        // Check cache
        if let cached = cacheService.getCachedMatches(for: cacheKey) {
            return cached
        }
        
        let response: MatchAPIResponse = try await apiService.request(
            .matchesByDateRange(from: from, to: to)
        )
        let matches = response.response.map { $0.toMatch() }
        
        // Cache for 24 hours (historical data doesn't change)
        cacheService.cacheMatches(matches, for: cacheKey, ttl: CachePolicy.pastMatches.ttl)
        
        #if DEBUG
        print("📜 Fetched \(matches.count) past matches")
        #endif
        
        return matches
    }
    
    // MARK: - Match Details
    
    func fetchMatchDetails(matchId: Int) async throws -> Match {
        // Check cache
        if let cached = cacheService.getCachedMatch(id: matchId) {
            // If match is live, don't use cache older than 15 seconds
            if cached.isLive, let cacheDate = cached.lastUpdated,
               Date().timeIntervalSince(cacheDate) < 15 {
                return cached
            } else if !cached.isLive {
                return cached
            }
        }
        
        let response: MatchAPIResponse = try await apiService.request(.matchById(matchId))
        guard let matchData = response.response.first else {
            throw APIError.noData
        }
        
        var match = matchData.toMatch()
        match.lastUpdated = Date()
        
        // Cache based on match status
        cacheService.cacheMatch(match)
        
        #if DEBUG
        print("🔍 Fetched match details for ID: \(matchId)")
        #endif
        
        return match
    }
    
    // MARK: - Auto-refresh for Live Matches
    
    func startLiveMatchesAutoRefresh() {
        stopLiveMatchesAutoRefresh() // Stop any existing timer
        
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { [weak self] in
                try? await self?.refreshLiveMatches()
            }
        }
        
        // Keep timer running in background
        RunLoop.current.add(refreshTimer!, forMode: .common)
        
        #if DEBUG
        print("▶️ Started live matches auto-refresh (every \(Int(refreshInterval))s)")
        #endif
    }
    
    func stopLiveMatchesAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        
        #if DEBUG
        print("⏸️ Stopped live matches auto-refresh")
        #endif
    }
    
    // MARK: - Cache Management
    
    func clearCache() {
        cacheService.clearCache()
    }
    
    func clearExpiredCache() {
        cacheService.clearExpiredCache()
    }
}

// MARK: - Convenience Extensions

extension MatchService {
    /// Fetch matches for today
    func fetchTodayMatches() async throws -> [Match] {
        try await fetchMatchesByDate(Date())
    }
    
    /// Fetch matches for tomorrow
    func fetchTomorrowMatches() async throws -> [Match] {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        return try await fetchMatchesByDate(tomorrow)
    }
    
    /// Fetch matches for a specific team
    func fetchMatchesByTeam(teamId: Int, days: Int = 30) async throws -> [Match] {
        let today = Date()
        let future = Calendar.current.date(byAdding: .day, value: days, to: today) ?? today
        
        let response: MatchAPIResponse = try await apiService.request(
            .matchesByTeam(teamId: teamId, from: today, to: future)
        )
        
        return response.response.map { $0.toMatch() }
    }
    
    /// Fetch matches for a specific league
    func fetchMatchesByLeague(leagueId: Int, season: Int) async throws -> [Match] {
        let cacheKey = CacheKey.league(leagueId)
        
        if let cached = cacheService.getCachedMatches(for: cacheKey) {
            return cached
        }
        
        let response: MatchAPIResponse = try await apiService.request(
            .matchesByLeague(leagueId: leagueId, season: season)
        )
        let matches = response.response.map { $0.toMatch() }
        
        cacheService.cacheMatches(matches, for: cacheKey, ttl: 3600)
        
        return matches
    }
}
