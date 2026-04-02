import Foundation

struct SystemStatus: Codable {
    let syncStatus: SyncStatus
    let databaseHealth: DatabaseHealth
    let apiStatus: APIStatus
    let lastUpdated: Date
    
    init(syncStatus: SyncStatus, databaseHealth: DatabaseHealth, apiStatus: APIStatus, lastUpdated: Date = Date()) {
        self.syncStatus = syncStatus
        self.databaseHealth = databaseHealth
        self.apiStatus = apiStatus
        self.lastUpdated = lastUpdated
    }
}

struct SyncStatus: Codable {
    let isAutoSyncEnabled: Bool
    let lastSyncTime: Date?
    let syncStatus: SyncState
    let syncProgress: Double
    let errorMessage: String?
    
    enum SyncState: String, Codable, CaseIterable {
        case idle = "IDLE"
        case syncing = "SYNCING"
        case completed = "COMPLETED"
        case failed = "FAILED"
        
        var displayName: String {
            switch self {
            case .idle: return "Idle"
            case .syncing: return "Syncing"
            case .completed: return "Completed"
            case .failed: return "Failed"
            }
        }
        
        var icon: String {
            switch self {
            case .idle: return "circle"
            case .syncing: return "arrow.clockwise"
            case .completed: return "checkmark.circle.fill"
            case .failed: return "exclamationmark.triangle.fill"
            }
        }
        
        var color: String {
            switch self {
            case .idle: return "gray"
            case .syncing: return "blue"
            case .completed: return "green"
            case .failed: return "red"
            }
        }
    }
    
    init(isAutoSyncEnabled: Bool = true, lastSyncTime: Date? = nil, syncStatus: SyncState = .idle, syncProgress: Double = 0.0, errorMessage: String? = nil) {
        self.isAutoSyncEnabled = isAutoSyncEnabled
        self.lastSyncTime = lastSyncTime
        self.syncStatus = syncStatus
        self.syncProgress = syncProgress
        self.errorMessage = errorMessage
    }
}

struct DatabaseHealth: Codable {
    let storageUsed: Double // percentage
    let totalTables: Int
    let healthyTables: Int
    let tableStatuses: [TableStatus]
    let lastOptimized: Date?
    let cacheSize: Int64 // in bytes
    
    init(storageUsed: Double = 0.0, totalTables: Int = 0, healthyTables: Int = 0, tableStatuses: [TableStatus] = [], lastOptimized: Date? = nil, cacheSize: Int64 = 0) {
        self.storageUsed = storageUsed
        self.totalTables = totalTables
        self.healthyTables = healthyTables
        self.tableStatuses = tableStatuses
        self.lastOptimized = lastOptimized
        self.cacheSize = cacheSize
    }
    
    var isHealthy: Bool {
        return healthyTables == totalTables && storageUsed < 90.0
    }
    
    var formattedCacheSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: cacheSize)
    }
}

struct TableStatus: Codable {
    let name: String
    let isHealthy: Bool
    let recordCount: Int
    let lastUpdated: Date?
    let errorMessage: String?
    
    init(name: String, isHealthy: Bool = true, recordCount: Int = 0, lastUpdated: Date? = nil, errorMessage: String? = nil) {
        self.name = name
        self.isHealthy = isHealthy
        self.recordCount = recordCount
        self.lastUpdated = lastUpdated
        self.errorMessage = errorMessage
    }
}

struct APIStatus: Codable {
    let connections: [APIConnection]
    let lastChecked: Date
    let overallStatus: ConnectionStatus
    
    enum ConnectionStatus: String, Codable, CaseIterable {
        case allConnected = "ALL_CONNECTED"
        case someIssues = "SOME_ISSUES"
        case majorIssues = "MAJOR_ISSUES"
        case offline = "OFFLINE"
        
        var displayName: String {
            switch self {
            case .allConnected: return "All Connected"
            case .someIssues: return "Some Issues"
            case .majorIssues: return "Major Issues"
            case .offline: return "Offline"
            }
        }
        
        var color: String {
            switch self {
            case .allConnected: return "green"
            case .someIssues: return "orange"
            case .majorIssues: return "red"
            case .offline: return "gray"
            }
        }
    }
    
    init(connections: [APIConnection] = [], lastChecked: Date = Date(), overallStatus: ConnectionStatus = .allConnected) {
        self.connections = connections
        self.lastChecked = lastChecked
        self.overallStatus = overallStatus
    }
}

struct APIConnection: Codable {
    let name: String
    let url: String
    let status: ConnectionState
    let responseTime: Double? // in milliseconds
    let lastChecked: Date
    let errorMessage: String?
    
    enum ConnectionState: String, Codable, CaseIterable {
        case connected = "CONNECTED"
        case slow = "SLOW"
        case timeout = "TIMEOUT"
        case error = "ERROR"
        case offline = "OFFLINE"
        
        var displayName: String {
            switch self {
            case .connected: return "Connected"
            case .slow: return "Slow Response"
            case .timeout: return "Timeout"
            case .error: return "Error"
            case .offline: return "Offline"
            }
        }
        
        var icon: String {
            switch self {
            case .connected: return "checkmark.circle.fill"
            case .slow: return "exclamationmark.triangle.fill"
            case .timeout: return "clock.fill"
            case .error: return "xmark.circle.fill"
            case .offline: return "wifi.slash"
            }
        }
        
        var color: String {
            switch self {
            case .connected: return "green"
            case .slow: return "orange"
            case .timeout: return "red"
            case .error: return "red"
            case .offline: return "gray"
            }
        }
    }
    
    init(name: String, url: String, status: ConnectionState, responseTime: Double? = nil, lastChecked: Date = Date(), errorMessage: String? = nil) {
        self.name = name
        self.url = url
        self.status = status
        self.responseTime = responseTime
        self.lastChecked = lastChecked
        self.errorMessage = errorMessage
    }
}

struct SyncLog: Identifiable, Codable {
    let id: Int
    let timestamp: Date
    let type: LogType
    let message: String
    let details: String?
    
    enum LogType: String, Codable, CaseIterable {
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
        case success = "SUCCESS"
        
        var icon: String {
            switch self {
            case .info: return "info.circle"
            case .warning: return "exclamationmark.triangle"
            case .error: return "xmark.circle"
            case .success: return "checkmark.circle"
            }
        }
        
        var color: String {
            switch self {
            case .info: return "blue"
            case .warning: return "orange"
            case .error: return "red"
            case .success: return "green"
            }
        }
    }
    
    init(id: Int, timestamp: Date, type: LogType, message: String, details: String? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.message = message
        self.details = details
    }
}

// MARK: - Mock Data
extension SystemStatus {
    static let mockSystemStatus = SystemStatus(
        syncStatus: SyncStatus(
            isAutoSyncEnabled: true,
            lastSyncTime: Date().addingTimeInterval(-300), // 5 minutes ago
            syncStatus: .completed,
            syncProgress: 1.0,
            errorMessage: nil
        ),
        databaseHealth: DatabaseHealth(
            storageUsed: 45.0,
            totalTables: 4,
            healthyTables: 4,
            tableStatuses: [
                TableStatus(name: "Matches", isHealthy: true, recordCount: 1250, lastUpdated: Date().addingTimeInterval(-300)),
                TableStatus(name: "Teams", isHealthy: true, recordCount: 320, lastUpdated: Date().addingTimeInterval(-600)),
                TableStatus(name: "Users", isHealthy: true, recordCount: 1, lastUpdated: Date().addingTimeInterval(-1200)),
                TableStatus(name: "Logs", isHealthy: true, recordCount: 45, lastUpdated: Date().addingTimeInterval(-60))
            ],
            lastOptimized: Date().addingTimeInterval(-86400), // 1 day ago
            cacheSize: 25 * 1024 * 1024 // 25 MB
        ),
        apiStatus: APIStatus(
            connections: [
                APIConnection(name: "Match Data API", url: "https://api-football.com/v4/matches", status: .connected, responseTime: 150.0, lastChecked: Date().addingTimeInterval(-30)),
                APIConnection(name: "User Stats API", url: "https://api-football.com/v4/statistics", status: .connected, responseTime: 200.0, lastChecked: Date().addingTimeInterval(-30)),
                APIConnection(name: "News Feed API", url: "https://api-football.com/v4/news", status: .slow, responseTime: 2500.0, lastChecked: Date().addingTimeInterval(-30), errorMessage: "Slow response time"),
                APIConnection(name: "Live Scores API", url: "https://api-football.com/v4/live", status: .connected, responseTime: 180.0, lastChecked: Date().addingTimeInterval(-30))
            ],
            lastChecked: Date().addingTimeInterval(-30),
            overallStatus: .someIssues
        )
    )
}

extension SyncLog {
    static let mockSyncLogs: [SyncLog] = [
        SyncLog(id: 1, timestamp: Date().addingTimeInterval(-300), type: .success, message: "Sync completed successfully", details: "Updated 45 matches, 12 teams"),
        SyncLog(id: 2, timestamp: Date().addingTimeInterval(-600), type: .info, message: "Starting automatic sync", details: "Checking for updates..."),
        SyncLog(id: 3, timestamp: Date().addingTimeInterval(-900), type: .warning, message: "Slow API response", details: "News Feed API took 2.5s to respond"),
        SyncLog(id: 4, timestamp: Date().addingTimeInterval(-1200), type: .success, message: "Database optimized", details: "Cleaned up 15MB of old cache data"),
        SyncLog(id: 5, timestamp: Date().addingTimeInterval(-1800), type: .error, message: "Sync failed", details: "Network timeout after 30 seconds")
    ]
}
