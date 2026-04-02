import Foundation

// MARK: - Cache Key

enum CacheKey: Hashable {
    case live
    case date(Date)
    case dateRange(from: Date, to: Date)
    case match(Int)
    case team(Int)
    case league(Int)
    
    var identifier: String {
        switch self {
        case .live:
            return "live"
        case .date(let date):
            return "date_\(Int(date.timeIntervalSince1970))"
        case .dateRange(let from, let to):
            return "range_\(Int(from.timeIntervalSince1970))_\(Int(to.timeIntervalSince1970))"
        case .match(let id):
            return "match_\(id)"
        case .team(let id):
            return "team_\(id)"
        case .league(let id):
            return "league_\(id)"
        }
    }
}

// MARK: - Cache Service

class MatchCacheService {
    private var memoryCache: [String: CacheEntry] = [:]
    private let cacheQueue = DispatchQueue(label: "com.sportsiq.cache", attributes: .concurrent)
    private let maxCacheSize = 100 // Maximum number of cache entries
    
    struct CacheEntry {
        let matches: [Match]
        let expiryDate: Date
        let createdAt: Date
        
        var isExpired: Bool {
            Date() > expiryDate
        }
        
        var age: TimeInterval {
            Date().timeIntervalSince(createdAt)
        }
    }
    
    // MARK: - Cache Matches
    
    func cacheMatches(_ matches: [Match], for key: CacheKey, ttl: TimeInterval) {
        let expiryDate = Date().addingTimeInterval(ttl)
        let entry = CacheEntry(matches: matches, expiryDate: expiryDate, createdAt: Date())
        
        cacheQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            self.memoryCache[key.identifier] = entry
            
            // Enforce cache size limit
            if self.memoryCache.count > self.maxCacheSize {
                self.evictOldestEntries()
            }
        }
        
        #if DEBUG
        print("💾 Cached \(matches.count) matches for key: \(key.identifier) (TTL: \(ttl)s)")
        #endif
    }
    
    func cacheMatch(_ match: Match) {
        let key = CacheKey.match(match.id)
        let ttl: TimeInterval = match.isLive ? 15 : 3600
        cacheMatches([match], for: key, ttl: ttl)
    }
    
    // MARK: - Retrieve from Cache
    
    func getCachedMatches(for key: CacheKey) -> [Match]? {
        var result: [Match]?
        
        cacheQueue.sync {
            guard let entry = memoryCache[key.identifier] else {
                return
            }
            
            if entry.isExpired {
                #if DEBUG
                print("⏰ Cache expired for key: \(key.identifier)")
                #endif
                return
            }
            
            result = entry.matches
            
            #if DEBUG
            print("✅ Cache hit for key: \(key.identifier) (\(entry.matches.count) matches, age: \(Int(entry.age))s)")
            #endif
        }
        
        return result
    }
    
    func getCachedMatch(id: Int) -> Match? {
        getCachedMatches(for: .match(id))?.first
    }
    
    // MARK: - Cache Management
    
    func clearCache() {
        cacheQueue.async(flags: .barrier) { [weak self] in
            self?.memoryCache.removeAll()
            #if DEBUG
            print("🗑️ Cache cleared")
            #endif
        }
    }
    
    func clearExpiredCache() {
        cacheQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            let beforeCount = self.memoryCache.count
            self.memoryCache = self.memoryCache.filter { !$0.value.isExpired }
            let afterCount = self.memoryCache.count
            
            #if DEBUG
            if beforeCount != afterCount {
                print("🧹 Cleared \(beforeCount - afterCount) expired cache entries")
            }
            #endif
        }
    }
    
    private func evictOldestEntries() {
        // Remove oldest 20% of entries when cache is full
        let entriesToRemove = maxCacheSize / 5
        let sorted = memoryCache.sorted { $0.value.createdAt < $1.value.createdAt }
        
        for i in 0..<min(entriesToRemove, sorted.count) {
            memoryCache.removeValue(forKey: sorted[i].key)
        }
        
        #if DEBUG
        print("🧹 Evicted \(entriesToRemove) oldest cache entries")
        #endif
    }
    
    func invalidateCache(for key: CacheKey) {
        cacheQueue.async(flags: .barrier) { [weak self] in
            self?.memoryCache.removeValue(forKey: key.identifier)
            #if DEBUG
            print("❌ Invalidated cache for key: \(key.identifier)")
            #endif
        }
    }
    
    // MARK: - Cache Statistics
    
    func getCacheStats() -> CacheStats {
        var stats = CacheStats()
        
        cacheQueue.sync {
            stats.totalEntries = memoryCache.count
            stats.expiredEntries = memoryCache.values.filter { $0.isExpired }.count
            stats.totalMatches = memoryCache.values.reduce(0) { $0 + $1.matches.count }
        }
        
        return stats
    }
    
    struct CacheStats {
        var totalEntries: Int = 0
        var expiredEntries: Int = 0
        var totalMatches: Int = 0
        
        var validEntries: Int {
            totalEntries - expiredEntries
        }
    }
}

// MARK: - Cache Policy

enum CachePolicy {
    case liveMatches
    case todayMatches
    case upcomingMatches
    case pastMatches
    case matchDetails(isLive: Bool)
    
    var ttl: TimeInterval {
        switch self {
        case .liveMatches:
            return 15 // 15 seconds
        case .todayMatches:
            return 300 // 5 minutes
        case .upcomingMatches:
            return 3600 // 1 hour
        case .pastMatches:
            return 86400 // 24 hours
        case .matchDetails(let isLive):
            return isLive ? 15 : 3600
        }
    }
}
