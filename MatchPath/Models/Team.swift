import Foundation

struct Team: Identifiable, Codable, Hashable {
    let id: Int
    let name: String
    let shortName: String
    let logo: String?
    let stadium: String?
    let city: String?
    let country: String?
    let founded: Int?
    let colors: TeamColors?
    let isFavorite: Bool
    
    struct TeamColors: Codable, Hashable {
        let primary: String
        let secondary: String?
        let accent: String?
    }
    
    init(id: Int, name: String, shortName: String, logo: String? = nil, stadium: String? = nil, city: String? = nil, country: String? = nil, founded: Int? = nil, colors: TeamColors? = nil, isFavorite: Bool = false) {
        self.id = id
        self.name = name
        self.shortName = shortName
        self.logo = logo
        self.stadium = stadium
        self.city = city
        self.country = country
        self.founded = founded
        self.colors = colors
        self.isFavorite = isFavorite
    }
}

// MARK: - Mock Data
extension Team {
    static let mockTeams: [Team] = [
        Team(id: 1, name: "Manchester United", shortName: "MUN", logo: "manchester_united", stadium: "Old Trafford", city: "Manchester", country: "England", founded: 1878, colors: TeamColors(primary: "#DA020E", secondary: "#FBE122", accent: "#000000")),
        Team(id: 2, name: "Liverpool", shortName: "LIV", logo: "liverpool", stadium: "Anfield", city: "Liverpool", country: "England", founded: 1892, colors: TeamColors(primary: "#C8102E", secondary: "#F6EB61", accent: "#000000")),
        Team(id: 3, name: "Arsenal", shortName: "ARS", logo: "arsenal", stadium: "Emirates Stadium", city: "London", country: "England", founded: 1886, colors: TeamColors(primary: "#EF0107", secondary: "#FFFFFF", accent: "#023474")),
        Team(id: 4, name: "Chelsea", shortName: "CHE", logo: "chelsea", stadium: "Stamford Bridge", city: "London", country: "England", founded: 1905, colors: TeamColors(primary: "#034694", secondary: "#FFFFFF", accent: "#000000")),
        Team(id: 5, name: "Manchester City", shortName: "MCI", logo: "manchester_city", stadium: "Etihad Stadium", city: "Manchester", country: "England", founded: 1880, colors: TeamColors(primary: "#6CABDD", secondary: "#FFFFFF", accent: "#000000")),
        Team(id: 6, name: "Real Madrid", shortName: "RMA", logo: "real_madrid", stadium: "Santiago Bernabéu", city: "Madrid", country: "Spain", founded: 1902, colors: TeamColors(primary: "#FFFFFF", secondary: "#FEBE10", accent: "#000000")),
        Team(id: 7, name: "Barcelona", shortName: "BAR", logo: "barcelona", stadium: "Camp Nou", city: "Barcelona", country: "Spain", founded: 1899, colors: TeamColors(primary: "#A50044", secondary: "#004D98", accent: "#FFFFFF")),
        Team(id: 8, name: "Bayern Munich", shortName: "BAY", logo: "bayern_munich", stadium: "Allianz Arena", city: "Munich", country: "Germany", founded: 1900, colors: TeamColors(primary: "#DC052D", secondary: "#FFFFFF", accent: "#000000"))
    ]
}
