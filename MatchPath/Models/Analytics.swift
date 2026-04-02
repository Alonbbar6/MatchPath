import Foundation

struct AnalyticsData: Codable {
    let userStats: UserAnalytics
    let matchStats: MatchAnalytics
    let teamStats: TeamAnalytics
    let dateRange: DateRange
    let generatedAt: Date
    
    init(userStats: UserAnalytics, matchStats: MatchAnalytics, teamStats: TeamAnalytics, dateRange: DateRange, generatedAt: Date = Date()) {
        self.userStats = userStats
        self.matchStats = matchStats
        self.teamStats = teamStats
        self.dateRange = dateRange
        self.generatedAt = generatedAt
    }
}

struct UserAnalytics: Codable {
    let totalMatchesWatched: Int
    let totalMatchesLiked: Int
    let totalMatchesFavorited: Int
    let totalWatchTime: TimeInterval
    let averageRating: Double
    let mostActiveDay: String
    let favoriteTimeOfDay: String
    let watchTimeByDay: [String: TimeInterval]
    let activityTrend: [ActivityDataPoint]
    
    init(totalMatchesWatched: Int = 0, totalMatchesLiked: Int = 0, totalMatchesFavorited: Int = 0, totalWatchTime: TimeInterval = 0, averageRating: Double = 0.0, mostActiveDay: String = "Monday", favoriteTimeOfDay: String = "Evening", watchTimeByDay: [String: TimeInterval] = [:], activityTrend: [ActivityDataPoint] = []) {
        self.totalMatchesWatched = totalMatchesWatched
        self.totalMatchesLiked = totalMatchesLiked
        self.totalMatchesFavorited = totalMatchesFavorited
        self.totalWatchTime = totalWatchTime
        self.averageRating = averageRating
        self.mostActiveDay = mostActiveDay
        self.favoriteTimeOfDay = favoriteTimeOfDay
        self.watchTimeByDay = watchTimeByDay
        self.activityTrend = activityTrend
    }
}

struct MatchAnalytics: Codable {
    let topRatedMatches: [RatedMatch]
    let mostWatchedMatches: [WatchedMatch]
    let averageMatchRating: Double
    let totalMatchesRated: Int
    let ratingDistribution: [RatingDistribution]
    
    init(topRatedMatches: [RatedMatch] = [], mostWatchedMatches: [WatchedMatch] = [], averageMatchRating: Double = 0.0, totalMatchesRated: Int = 0, ratingDistribution: [RatingDistribution] = []) {
        self.topRatedMatches = topRatedMatches
        self.mostWatchedMatches = mostWatchedMatches
        self.averageMatchRating = averageMatchRating
        self.totalMatchesRated = totalMatchesRated
        self.ratingDistribution = ratingDistribution
    }
}

struct TeamAnalytics: Codable {
    let favoriteTeams: [TeamPerformance]
    let teamForm: [TeamFormData]
    let goalsScored: Int
    let goalsConceded: Int
    let winRate: Double
    let averageGoalsPerMatch: Double
    
    init(favoriteTeams: [TeamPerformance] = [], teamForm: [TeamFormData] = [], goalsScored: Int = 0, goalsConceded: Int = 0, winRate: Double = 0.0, averageGoalsPerMatch: Double = 0.0) {
        self.favoriteTeams = favoriteTeams
        self.teamForm = teamForm
        self.goalsScored = goalsScored
        self.goalsConceded = goalsConceded
        self.winRate = winRate
        self.averageGoalsPerMatch = averageGoalsPerMatch
    }
}

struct ActivityDataPoint: Codable {
    let date: Date
    let value: Double
    let type: ActivityType
    
    enum ActivityType: String, Codable {
        case watched = "WATCHED"
        case liked = "LIKED"
        case favorited = "FAVORITED"
        case rated = "RATED"
    }
}

struct RatedMatch: Codable, Identifiable {
    var id: Int { match.id }
    let match: Match
    let rating: Double
    let userRating: Double
    let totalRatings: Int
}

struct WatchedMatch: Codable {
    let match: Match
    let watchTime: TimeInterval
    let completionRate: Double
}

struct RatingDistribution: Codable {
    let rating: Int
    let count: Int
    let percentage: Double
}

struct TeamPerformance: Codable, Identifiable {
    var id: Int { team.id }
    let team: Team
    let matchesWatched: Int
    let winRate: Double
    let averageGoals: Double
    let recentForm: [String] // W, L, D, W, W
    let favoriteOpponent: Team?
    let leastFavoriteOpponent: Team?
}

struct TeamFormData: Codable {
    let team: Team
    let recentMatches: [Match]
    let form: [String] // Last 5 results
    let points: Int
    let position: Int
}

struct DateRange: Codable {
    let start: Date
    let end: Date
    let type: RangeType
    
    enum RangeType: String, Codable, CaseIterable {
        case thisWeek = "THIS_WEEK"
        case thisMonth = "THIS_MONTH"
        case lastMonth = "LAST_MONTH"
        case thisYear = "THIS_YEAR"
        case allTime = "ALL_TIME"
        case custom = "CUSTOM"
        
        var displayName: String {
            switch self {
            case .thisWeek: return "This Week"
            case .thisMonth: return "This Month"
            case .lastMonth: return "Last Month"
            case .thisYear: return "This Year"
            case .allTime: return "All Time"
            case .custom: return "Custom Range"
            }
        }
    }
}

// MARK: - Mock Data
extension AnalyticsData {
    static let mockAnalytics = AnalyticsData(
        userStats: UserAnalytics(
            totalMatchesWatched: 45,
            totalMatchesLiked: 32,
            totalMatchesFavorited: 18,
            totalWatchTime: 16200, // 4.5 hours
            averageRating: 4.2,
            mostActiveDay: "Saturday",
            favoriteTimeOfDay: "Evening",
            watchTimeByDay: [
                "Monday": 1800,
                "Tuesday": 1200,
                "Wednesday": 2400,
                "Thursday": 1500,
                "Friday": 2100,
                "Saturday": 3600,
                "Sunday": 3600
            ],
            activityTrend: []
        ),
        matchStats: MatchAnalytics(
            topRatedMatches: [],
            mostWatchedMatches: [],
            averageMatchRating: 4.2,
            totalMatchesRated: 18,
            ratingDistribution: [
                RatingDistribution(rating: 5, count: 8, percentage: 44.4),
                RatingDistribution(rating: 4, count: 6, percentage: 33.3),
                RatingDistribution(rating: 3, count: 3, percentage: 16.7),
                RatingDistribution(rating: 2, count: 1, percentage: 5.6),
                RatingDistribution(rating: 1, count: 0, percentage: 0.0)
            ]
        ),
        teamStats: TeamAnalytics(
            favoriteTeams: [],
            teamForm: [],
            goalsScored: 28,
            goalsConceded: 15,
            winRate: 0.75,
            averageGoalsPerMatch: 2.8
        ),
        dateRange: DateRange(
            start: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
            end: Date(),
            type: .thisWeek
        )
    )
}
