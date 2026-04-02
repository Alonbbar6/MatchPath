import Foundation

protocol CacheServiceProtocol {
    func getCachedTeams() -> [Team]?
    func cacheTeams(_ teams: [Team])
    func getCachedLeagues() -> [League]?
    func cacheLeagues(_ leagues: [League])
    func getCachedMatches(for league: League?) -> [Match]?
    func cacheMatches(_ matches: [Match], for league: League?)
    func getCachedStandings(for league: League) -> [Standing]?
    func cacheStandings(_ standings: [Standing], for league: League)
    func updateFavoriteTeam(_ team: Team)
    func clearCache()
}

class CacheService: CacheServiceProtocol {
    private let userDefaults = UserDefaults.standard
    private let cacheExpirationTime: TimeInterval = 300 // 5 minutes
    
    // MARK: - Teams
    func getCachedTeams() -> [Team]? {
        guard let data = userDefaults.data(forKey: "cached_teams"),
              let teams = try? JSONDecoder().decode([Team].self, from: data),
              isCacheValid(for: "teams_cache_time") else {
            return nil
        }
        return teams
    }
    
    func cacheTeams(_ teams: [Team]) {
        if let data = try? JSONEncoder().encode(teams) {
            userDefaults.set(data, forKey: "cached_teams")
            userDefaults.set(Date(), forKey: "teams_cache_time")
        }
    }
    
    // MARK: - Leagues
    func getCachedLeagues() -> [League]? {
        guard let data = userDefaults.data(forKey: "cached_leagues"),
              let leagues = try? JSONDecoder().decode([League].self, from: data),
              isCacheValid(for: "leagues_cache_time") else {
            return nil
        }
        return leagues
    }
    
    func cacheLeagues(_ leagues: [League]) {
        if let data = try? JSONEncoder().encode(leagues) {
            userDefaults.set(data, forKey: "cached_leagues")
            userDefaults.set(Date(), forKey: "leagues_cache_time")
        }
    }
    
    // MARK: - Matches
    func getCachedMatches(for league: League?) -> [Match]? {
        let key = league != nil ? "cached_matches_\(league!.id)" : "cached_matches_all"
        let timeKey = league != nil ? "matches_cache_time_\(league!.id)" : "matches_cache_time_all"
        
        guard let data = userDefaults.data(forKey: key),
              let matches = try? JSONDecoder().decode([Match].self, from: data),
              isCacheValid(for: timeKey) else {
            return nil
        }
        return matches
    }
    
    func cacheMatches(_ matches: [Match], for league: League?) {
        let key = league != nil ? "cached_matches_\(league!.id)" : "cached_matches_all"
        let timeKey = league != nil ? "matches_cache_time_\(league!.id)" : "matches_cache_time_all"
        
        if let data = try? JSONEncoder().encode(matches) {
            userDefaults.set(data, forKey: key)
            userDefaults.set(Date(), forKey: timeKey)
        }
    }
    
    // MARK: - Standings
    func getCachedStandings(for league: League) -> [Standing]? {
        let key = "cached_standings_\(league.id)"
        let timeKey = "standings_cache_time_\(league.id)"
        
        guard let data = userDefaults.data(forKey: key),
              let standings = try? JSONDecoder().decode([Standing].self, from: data),
              isCacheValid(for: timeKey) else {
            return nil
        }
        return standings
    }
    
    func cacheStandings(_ standings: [Standing], for league: League) {
        let key = "cached_standings_\(league.id)"
        let timeKey = "standings_cache_time_\(league.id)"
        
        if let data = try? JSONEncoder().encode(standings) {
            userDefaults.set(data, forKey: key)
            userDefaults.set(Date(), forKey: timeKey)
        }
    }
    
    // MARK: - Favorites
    func updateFavoriteTeam(_ team: Team) {
        var favoriteTeamIds = getFavoriteTeamIds()
        if team.isFavorite {
            if !favoriteTeamIds.contains(team.id) {
                favoriteTeamIds.append(team.id)
            }
        } else {
            favoriteTeamIds.removeAll { $0 == team.id }
        }
        userDefaults.set(favoriteTeamIds, forKey: "favorite_team_ids")
    }
    
    private func getFavoriteTeamIds() -> [Int] {
        return userDefaults.object(forKey: "favorite_team_ids") as? [Int] ?? []
    }
    
    // MARK: - Cache Management
    func clearCache() {
        let keys = userDefaults.dictionaryRepresentation().keys
        for key in keys {
            if key.hasPrefix("cached_") || key.hasPrefix("standings_cache_time") || key.hasPrefix("matches_cache_time") || key.hasPrefix("teams_cache_time") || key.hasPrefix("leagues_cache_time") {
                userDefaults.removeObject(forKey: key)
            }
        }
    }
    
    private func isCacheValid(for timeKey: String) -> Bool {
        guard let cacheTime = userDefaults.object(forKey: timeKey) as? Date else {
            return false
        }
        return Date().timeIntervalSince(cacheTime) < cacheExpirationTime
    }
}
