import Foundation

struct Player: Identifiable, Codable, Hashable {
    let id: Int
    let name: String
    let position: Position
    let team: Team
    let number: Int?
    let nationality: String?
    let age: Int?
    let height: String?
    let weight: String?
    let marketValue: String?
    let contractUntil: String?
    let photo: String?
    
    enum Position: String, Codable, CaseIterable {
        case goalkeeper = "Goalkeeper"
        case defender = "Defender"
        case midfielder = "Midfielder"
        case forward = "Forward"
        
        var shortName: String {
            switch self {
            case .goalkeeper: return "GK"
            case .defender: return "DEF"
            case .midfielder: return "MID"
            case .forward: return "FWD"
            }
        }
        
        var icon: String {
            switch self {
            case .goalkeeper: return "shield.fill"
            case .defender: return "rectangle.stack.fill"
            case .midfielder: return "circle.fill"
            case .forward: return "target"
            }
        }
    }
    
    init(id: Int, name: String, position: Position, team: Team, number: Int? = nil, nationality: String? = nil, age: Int? = nil, height: String? = nil, weight: String? = nil, marketValue: String? = nil, contractUntil: String? = nil, photo: String? = nil) {
        self.id = id
        self.name = name
        self.position = position
        self.team = team
        self.number = number
        self.nationality = nationality
        self.age = age
        self.height = height
        self.weight = weight
        self.marketValue = marketValue
        self.contractUntil = contractUntil
        self.photo = photo
    }
}

// MARK: - Mock Data
extension Player {
    static let mockPlayers: [Player] = [
        Player(id: 1, name: "Erling Haaland", position: .forward, team: Team.mockTeams[4], number: 9, nationality: "Norway", age: 24, height: "1.94m", weight: "88kg", marketValue: "€180M", contractUntil: "2027", photo: "haaland"),
        Player(id: 2, name: "Kevin De Bruyne", position: .midfielder, team: Team.mockTeams[4], number: 17, nationality: "Belgium", age: 33, height: "1.81m", weight: "70kg", marketValue: "€60M", contractUntil: "2025", photo: "de_bruyne"),
        Player(id: 3, name: "Mohamed Salah", position: .forward, team: Team.mockTeams[1], number: 11, nationality: "Egypt", age: 32, height: "1.75m", weight: "71kg", marketValue: "€55M", contractUntil: "2025", photo: "salah"),
        Player(id: 4, name: "Virgil van Dijk", position: .defender, team: Team.mockTeams[1], number: 4, nationality: "Netherlands", age: 33, height: "1.93m", weight: "92kg", marketValue: "€8M", contractUntil: "2025", photo: "van_dijk"),
        Player(id: 5, name: "Bruno Fernandes", position: .midfielder, team: Team.mockTeams[0], number: 18, nationality: "Portugal", age: 30, height: "1.79m", weight: "69kg", marketValue: "€70M", contractUntil: "2026", photo: "bruno_fernandes")
    ]
}
