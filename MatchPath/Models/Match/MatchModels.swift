import Foundation

// MARK: - Main Match Model

struct Match: Identifiable, Codable, Hashable {
    let id: Int
    let referee: String?
    let timezone: String
    let date: Date
    let timestamp: Int
    let venue: Venue?
    let status: MatchStatus
    let league: MatchLeague
    let teams: MatchTeams
    let goals: Goals
    let score: Score
    
    // Local properties (not from API)
    var isFavorite: Bool = false
    var isFavorited: Bool = false  // Alias for compatibility
    var isLiked: Bool = false
    var userRating: Double?
    var lastUpdated: Date?
    var cacheExpiry: Date?
    
    var isLive: Bool {
        status.isLive
    }
    
    var isFinished: Bool {
        status.isFinished
    }
    
    var isUpcoming: Bool {
        status.isScheduled
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var isPast: Bool {
        isFinished || date < Date()
    }
    
    var displayTime: String {
        if isLive {
            return status.elapsed != nil ? "\(status.elapsed!)'" : "LIVE"
        } else if isUpcoming {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
        } else {
            return "FT"
        }
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Venue

struct Venue: Codable, Hashable {
    let id: Int?
    let name: String?
    let city: String?
}

// MARK: - Match Status

struct MatchStatus: Codable, Hashable {
    let long: String  // "Match Finished", "First Half", etc.
    let short: String // "FT", "1H", "2H", "HT", "LIVE", "NS"
    let elapsed: Int?
    
    var isLive: Bool {
        ["1H", "2H", "HT", "LIVE", "ET", "BT", "P"].contains(short)
    }
    
    var isFinished: Bool {
        ["FT", "AET", "PEN", "PST", "CANC", "ABD", "AWD", "WO"].contains(short)
    }
    
    var isScheduled: Bool {
        short == "NS" || short == "TBD"
    }
    
    var isActive: Bool {
        isLive
    }
    
    var displayText: String {
        switch short {
        case "NS": return "Not Started"
        case "1H": return "1st Half"
        case "2H": return "2nd Half"
        case "HT": return "Half Time"
        case "FT": return "Full Time"
        case "ET": return "Extra Time"
        case "PEN": return "Penalties"
        case "AET": return "After ET"
        case "LIVE": return "Live"
        default: return long
        }
    }
}

// MARK: - Match Teams

struct MatchTeams: Codable, Hashable {
    let home: MatchTeam
    let away: MatchTeam
}

struct MatchTeam: Codable, Hashable, Identifiable {
    let id: Int
    let name: String
    let logo: String
    let winner: Bool?
}

// MARK: - Goals

struct Goals: Codable, Hashable {
    let home: Int?
    let away: Int?
    
    var homeScore: Int {
        home ?? 0
    }
    
    var awayScore: Int {
        away ?? 0
    }
}

// MARK: - Score

struct Score: Codable, Hashable {
    let halftime: Goals
    let fulltime: Goals
    let extratime: Goals?
    let penalty: Goals?
}

// MARK: - Match League

struct MatchLeague: Codable, Hashable, Identifiable {
    let id: Int
    let name: String
    let country: String
    let logo: String?
    let flag: String?
    let season: Int
    let round: String?
}

// MARK: - API Response Models

struct MatchAPIResponse: Codable {
    let get: String?
    let parameters: [String: AnyCodable]?
    let errors: [String: String]?
    let results: Int
    let paging: Paging
    let response: [MatchData]
}

struct MatchData: Codable {
    let fixture: APIFixture
    let league: APILeague
    let teams: APITeams
    let goals: Goals
    let score: Score
}

struct APIFixture: Codable {
    let id: Int
    let referee: String?
    let timezone: String
    let date: String
    let timestamp: Int
    let venue: Venue?
    let status: MatchStatus
}

struct APILeague: Codable {
    let id: Int
    let name: String
    let country: String
    let logo: String?
    let flag: String?
    let season: Int
    let round: String?
}

struct APITeams: Codable {
    let home: APITeam
    let away: APITeam
}

struct APITeam: Codable {
    let id: Int
    let name: String
    let logo: String
    let winner: Bool?
}

struct Paging: Codable {
    let current: Int
    let total: Int
}

// MARK: - AnyCodable Helper for Dynamic Parameters

struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else {
            value = ""
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        if let intValue = value as? Int {
            try container.encode(intValue)
        } else if let stringValue = value as? String {
            try container.encode(stringValue)
        } else if let boolValue = value as? Bool {
            try container.encode(boolValue)
        } else if let doubleValue = value as? Double {
            try container.encode(doubleValue)
        }
    }
}

// MARK: - Conversion Extension

extension MatchData {
    func toMatch() -> Match {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let matchDate = dateFormatter.date(from: fixture.date) ?? Date()
        
        return Match(
            id: fixture.id,
            referee: fixture.referee,
            timezone: fixture.timezone,
            date: matchDate,
            timestamp: fixture.timestamp,
            venue: fixture.venue,
            status: fixture.status,
            league: MatchLeague(
                id: league.id,
                name: league.name,
                country: league.country,
                logo: league.logo,
                flag: league.flag,
                season: league.season,
                round: league.round
            ),
            teams: MatchTeams(
                home: MatchTeam(
                    id: teams.home.id,
                    name: teams.home.name,
                    logo: teams.home.logo,
                    winner: teams.home.winner
                ),
                away: MatchTeam(
                    id: teams.away.id,
                    name: teams.away.name,
                    logo: teams.away.logo,
                    winner: teams.away.winner
                )
            ),
            goals: goals,
            score: score,
            lastUpdated: Date()
        )
    }
}

// MARK: - Mock Data for Testing

extension Match {
    static var mockLiveMatch: Match {
        Match(
            id: 1,
            referee: "Michael Oliver",
            timezone: "UTC",
            date: Date(),
            timestamp: Int(Date().timeIntervalSince1970),
            venue: Venue(id: 1, name: "Old Trafford", city: "Manchester"),
            status: MatchStatus(long: "First Half", short: "1H", elapsed: 23),
            league: MatchLeague(id: 39, name: "Premier League", country: "England", logo: nil, flag: nil, season: 2025, round: "Regular Season - 10"),
            teams: MatchTeams(
                home: MatchTeam(id: 33, name: "Manchester United", logo: "", winner: nil),
                away: MatchTeam(id: 34, name: "Newcastle", logo: "", winner: nil)
            ),
            goals: Goals(home: 1, away: 0),
            score: Score(
                halftime: Goals(home: nil, away: nil),
                fulltime: Goals(home: nil, away: nil),
                extratime: nil,
                penalty: nil
            )
        )
    }
    
    static var mockUpcomingMatch: Match {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        return Match(
            id: 2,
            referee: nil,
            timezone: "UTC",
            date: tomorrow,
            timestamp: Int(tomorrow.timeIntervalSince1970),
            venue: Venue(id: 2, name: "Anfield", city: "Liverpool"),
            status: MatchStatus(long: "Not Started", short: "NS", elapsed: nil),
            league: MatchLeague(id: 39, name: "Premier League", country: "England", logo: nil, flag: nil, season: 2025, round: "Regular Season - 11"),
            teams: MatchTeams(
                home: MatchTeam(id: 40, name: "Liverpool", logo: "", winner: nil),
                away: MatchTeam(id: 50, name: "Manchester City", logo: "", winner: nil)
            ),
            goals: Goals(home: nil, away: nil),
            score: Score(
                halftime: Goals(home: nil, away: nil),
                fulltime: Goals(home: nil, away: nil),
                extratime: nil,
                penalty: nil
            )
        )
    }
    
    static var mockFinishedMatch: Match {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        return Match(
            id: 3,
            referee: "Anthony Taylor",
            timezone: "UTC",
            date: yesterday,
            timestamp: Int(yesterday.timeIntervalSince1970),
            venue: Venue(id: 3, name: "Emirates Stadium", city: "London"),
            status: MatchStatus(long: "Match Finished", short: "FT", elapsed: 90),
            league: MatchLeague(id: 39, name: "Premier League", country: "England", logo: nil, flag: nil, season: 2025, round: "Regular Season - 9"),
            teams: MatchTeams(
                home: MatchTeam(id: 42, name: "Arsenal", logo: "", winner: true),
                away: MatchTeam(id: 47, name: "Tottenham", logo: "", winner: false)
            ),
            goals: Goals(home: 3, away: 1),
            score: Score(
                halftime: Goals(home: 2, away: 0),
                fulltime: Goals(home: 3, away: 1),
                extratime: nil,
                penalty: nil
            )
        )
    }
    
    static var mockMatches: [Match] {
        [mockLiveMatch, mockUpcomingMatch, mockFinishedMatch]
    }
}

// MARK: - Compatibility Extensions for UI

extension Match {
    /// Compatibility: homeTeam property for existing UI
    var homeTeam: CompatibleTeam {
        CompatibleTeam(
            id: teams.home.id,
            name: teams.home.name,
            shortName: String(teams.home.name.prefix(3)).uppercased(),
            logo: teams.home.logo
        )
    }
    
    /// Compatibility: awayTeam property for existing UI
    var awayTeam: CompatibleTeam {
        CompatibleTeam(
            id: teams.away.id,
            name: teams.away.name,
            shortName: String(teams.away.name.prefix(3)).uppercased(),
            logo: teams.away.logo
        )
    }
    
    /// Compatibility: homeScore property
    var homeScore: Int? {
        goals.home
    }
    
    /// Compatibility: awayScore property
    var awayScore: Int? {
        goals.away
    }
    
    /// Compatibility: formatted date string
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    /// Compatibility: score string
    var scoreText: String {
        guard let home = goals.home, let away = goals.away else {
            return "vs"
        }
        return "\(home) - \(away)"
    }
}

/// Simplified team structure for UI compatibility
struct CompatibleTeam: Identifiable {
    let id: Int
    let name: String
    let shortName: String
    let logo: String
}

extension MatchLeague {
    /// Compatibility: shortName for UI
    var shortName: String {
        String(name.prefix(3)).uppercased()
    }
}

extension MatchStatus {
    /// Compatibility: enum-like status for existing UI
    enum StatusType {
        case scheduled
        case live
        case finished
        case halftime
    }
    
    var statusType: StatusType {
        if isLive {
            return short == "HT" ? .halftime : .live
        } else if isFinished {
            return .finished
        } else {
            return .scheduled
        }
    }
}
