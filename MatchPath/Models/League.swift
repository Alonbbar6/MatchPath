import Foundation

struct League: Identifiable, Codable, Hashable {
    let id: Int
    let name: String
    let shortName: String
    let country: String
    let logo: String?
    let season: String
    let isActive: Bool
    
    init(id: Int, name: String, shortName: String, country: String, logo: String? = nil, season: String, isActive: Bool = true) {
        self.id = id
        self.name = name
        self.shortName = shortName
        self.country = country
        self.logo = logo
        self.season = season
        self.isActive = isActive
    }
}

// MARK: - Mock Data
extension League {
    static let mockLeagues: [League] = [
        League(id: 1, name: "Premier League", shortName: "EPL", country: "England", logo: "premier_league", season: "2024/25"),
        League(id: 2, name: "La Liga", shortName: "LL", country: "Spain", logo: "la_liga", season: "2024/25"),
        League(id: 3, name: "Serie A", shortName: "SA", country: "Italy", logo: "serie_a", season: "2024/25"),
        League(id: 4, name: "Bundesliga", shortName: "BL", country: "Germany", logo: "bundesliga", season: "2024/25"),
        League(id: 5, name: "Ligue 1", shortName: "L1", country: "France", logo: "ligue_1", season: "2024/25")
    ]
}
