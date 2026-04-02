import Foundation

enum SportType: String, CaseIterable, Codable {
    case running = "Running"
    case cycling = "Cycling"
    case swimming = "Swimming"
    case soccer = "Soccer"
    case basketball = "Basketball"
    case tennis = "Tennis"
    case gym = "Gym"
    case yoga = "Yoga"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .running: return "figure.run"
        case .cycling: return "bicycle"
        case .swimming: return "figure.pool.swim"
        case .soccer: return "soccerball"
        case .basketball: return "basketball"
        case .tennis: return "tennisball"
        case .gym: return "dumbbell"
        case .yoga: return "figure.mind.and.body"
        case .other: return "sportscourt"
        }
    }
}

struct Workout: Identifiable, Codable {
    var id = UUID()
    var sportType: SportType
    var duration: TimeInterval // in seconds
    var distance: Double? // in kilometers
    var calories: Int?
    var date: Date
    var notes: String?
    
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%dh %dm %ds", hours, minutes, seconds)
        } else if minutes > 0 {
            return String(format: "%dm %ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
    
    var formattedDistance: String? {
        guard let distance = distance else { return nil }
        return String(format: "%.2f km", distance)
    }
}
