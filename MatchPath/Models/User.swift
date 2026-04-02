import Foundation

struct User: Identifiable, Codable {
    let id: Int
    let username: String
    let email: String
    let avatar: String?
    let favoriteTeams: [Team]
    let favoriteLeagues: [League]
    let preferences: UserPreferences
    let stats: UserStats
    let createdAt: Date
    let lastActive: Date
    
    init(id: Int, username: String, email: String, avatar: String? = nil, favoriteTeams: [Team] = [], favoriteLeagues: [League] = [], preferences: UserPreferences = UserPreferences(), stats: UserStats = UserStats(), createdAt: Date = Date(), lastActive: Date = Date()) {
        self.id = id
        self.username = username
        self.email = email
        self.avatar = avatar
        self.favoriteTeams = favoriteTeams
        self.favoriteLeagues = favoriteLeagues
        self.preferences = preferences
        self.stats = stats
        self.createdAt = createdAt
        self.lastActive = lastActive
    }
}

struct UserPreferences: Codable {
    var notificationsEnabled: Bool
    var emailNotifications: Bool
    var pushNotifications: Bool
    var darkMode: Bool
    var language: String
    var timeZone: String
    var reminderTiming: Int // minutes before match
    var favoriteTeam: Team?
    
    init(notificationsEnabled: Bool = true, emailNotifications: Bool = true, pushNotifications: Bool = true, darkMode: Bool = false, language: String = "en", timeZone: String = "UTC", reminderTiming: Int = 30, favoriteTeam: Team? = nil) {
        self.notificationsEnabled = notificationsEnabled
        self.emailNotifications = emailNotifications
        self.pushNotifications = pushNotifications
        self.darkMode = darkMode
        self.language = language
        self.timeZone = timeZone
        self.reminderTiming = reminderTiming
        self.favoriteTeam = favoriteTeam
    }
}

struct UserStats: Codable {
    let matchesLiked: Int
    let matchesFavorited: Int
    let matchesRated: Int
    let averageRating: Double
    let totalWatchTime: TimeInterval // in seconds
    let favoriteTeam: Team?
    let mostWatchedLeague: League?
    
    init(matchesLiked: Int = 0, matchesFavorited: Int = 0, matchesRated: Int = 0, averageRating: Double = 0.0, totalWatchTime: TimeInterval = 0, favoriteTeam: Team? = nil, mostWatchedLeague: League? = nil) {
        self.matchesLiked = matchesLiked
        self.matchesFavorited = matchesFavorited
        self.matchesRated = matchesRated
        self.averageRating = averageRating
        self.totalWatchTime = totalWatchTime
        self.favoriteTeam = favoriteTeam
        self.mostWatchedLeague = mostWatchedLeague
    }
    
    var formattedWatchTime: String {
        let hours = Int(totalWatchTime) / 3600
        let minutes = Int(totalWatchTime) / 60 % 60
        return "\(hours)h \(minutes)m"
    }
}

struct UserActivity: Identifiable, Codable {
    let id: Int
    let type: ActivityType
    let match: Match
    let timestamp: Date
    let rating: Double?
    let comment: String?
    
    enum ActivityType: String, Codable, CaseIterable {
        case liked = "LIKED"
        case favorited = "FAVORITED"
        case rated = "RATED"
        case commented = "COMMENTED"
        case watched = "WATCHED"
        
        var icon: String {
            switch self {
            case .liked: return "heart.fill"
            case .favorited: return "star.fill"
            case .rated: return "star.leadinghalf.filled"
            case .commented: return "message.fill"
            case .watched: return "play.fill"
            }
        }
        
        var color: String {
            switch self {
            case .liked: return "red"
            case .favorited: return "yellow"
            case .rated: return "orange"
            case .commented: return "blue"
            case .watched: return "green"
            }
        }
    }
}

struct Reminder: Identifiable, Codable {
    let id: Int
    let match: Match
    let timing: Int // minutes before match
    let notificationType: NotificationType
    let isEnabled: Bool
    let createdAt: Date
    
    enum NotificationType: String, Codable, CaseIterable {
        case app = "APP"
        case email = "EMAIL"
        case both = "BOTH"
        
        var displayName: String {
            switch self {
            case .app: return "App Notification"
            case .email: return "Email"
            case .both: return "App + Email"
            }
        }
    }
}

// MARK: - Mock Data
extension User {
    static let mockUser = User(
        id: 1,
        username: "SoccerFan2024",
        email: "user@example.com",
        avatar: "user_avatar",
        favoriteTeams: [Team.mockTeams[0], Team.mockTeams[1]],
        favoriteLeagues: [League.mockLeagues[0], League.mockLeagues[1]],
        preferences: UserPreferences(
            notificationsEnabled: true,
            emailNotifications: true,
            pushNotifications: true,
            darkMode: false,
            language: "en",
            timeZone: "UTC",
            reminderTiming: 30,
            favoriteTeam: Team.mockTeams[0]
        ),
        stats: UserStats(
            matchesLiked: 25,
            matchesFavorited: 12,
            matchesRated: 18,
            averageRating: 4.2,
            totalWatchTime: 14400, // 4 hours
            favoriteTeam: Team.mockTeams[0],
            mostWatchedLeague: League.mockLeagues[0]
        )
    )
}

extension UserActivity {
    static let mockActivities: [UserActivity] = [
        UserActivity(id: 1, type: .liked, match: Match.mockMatches[0], timestamp: Date().addingTimeInterval(-3600), rating: nil, comment: nil),
        UserActivity(id: 2, type: .favorited, match: Match.mockMatches[1], timestamp: Date().addingTimeInterval(-7200), rating: nil, comment: nil),
        UserActivity(id: 3, type: .rated, match: Match.mockMatches[2], timestamp: Date().addingTimeInterval(-10800), rating: 4.5, comment: "Great match!"),
        UserActivity(id: 4, type: .commented, match: Match.mockMatches[0], timestamp: Date().addingTimeInterval(-14400), rating: nil, comment: "Amazing goals!")
    ]
}

extension Reminder {
    static let mockReminders: [Reminder] = [
        Reminder(id: 1, match: Match.mockMatches[1], timing: 30, notificationType: .app, isEnabled: true, createdAt: Date().addingTimeInterval(-86400)),
        Reminder(id: 2, match: Match.mockMatches[3], timing: 60, notificationType: .both, isEnabled: true, createdAt: Date().addingTimeInterval(-172800))
    ]
}
