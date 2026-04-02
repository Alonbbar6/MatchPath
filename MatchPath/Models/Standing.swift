import Foundation

struct Standing: Identifiable, Codable, Hashable {
    let id: Int
    let team: Team
    let position: Int
    let played: Int
    let won: Int
    let drawn: Int
    let lost: Int
    let goalsFor: Int
    let goalsAgainst: Int
    let goalDifference: Int
    let points: Int
    let form: [String] // Last 5 results: W, L, D, W, W
    
    init(id: Int, team: Team, position: Int, played: Int, won: Int, drawn: Int, lost: Int, goalsFor: Int, goalsAgainst: Int, goalDifference: Int, points: Int, form: [String] = []) {
        self.id = id
        self.team = team
        self.position = position
        self.played = played
        self.won = won
        self.drawn = drawn
        self.lost = lost
        self.goalsFor = goalsFor
        self.goalsAgainst = goalsAgainst
        self.goalDifference = goalDifference
        self.points = points
        self.form = form
    }
    
    var winPercentage: Double {
        guard played > 0 else { return 0.0 }
        return Double(won) / Double(played) * 100
    }
    
    var formString: String {
        return form.joined(separator: " ")
    }
}

// MARK: - Mock Data
extension Standing {
    static let mockStandings: [Standing] = [
        Standing(id: 1, team: Team.mockTeams[4], position: 1, played: 20, won: 15, drawn: 3, lost: 2, goalsFor: 45, goalsAgainst: 18, goalDifference: 27, points: 48, form: ["W", "W", "D", "W", "W"]),
        Standing(id: 2, team: Team.mockTeams[1], position: 2, played: 20, won: 14, drawn: 4, lost: 2, goalsFor: 42, goalsAgainst: 20, goalDifference: 22, points: 46, form: ["W", "D", "W", "W", "L"]),
        Standing(id: 3, team: Team.mockTeams[0], position: 3, played: 20, won: 13, drawn: 5, lost: 2, goalsFor: 38, goalsAgainst: 22, goalDifference: 16, points: 44, form: ["W", "W", "D", "W", "D"]),
        Standing(id: 4, team: Team.mockTeams[2], position: 4, played: 20, won: 12, drawn: 6, lost: 2, goalsFor: 35, goalsAgainst: 25, goalDifference: 10, points: 42, form: ["D", "W", "W", "L", "W"]),
        Standing(id: 5, team: Team.mockTeams[3], position: 5, played: 20, won: 11, drawn: 7, lost: 2, goalsFor: 32, goalsAgainst: 28, goalDifference: 4, points: 40, form: ["W", "D", "D", "W", "D"])
    ]
}
