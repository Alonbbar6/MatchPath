import Foundation

enum APIEndpoint {
    case liveMatches
    case matchesByDate(Date)
    case matchesByDateRange(from: Date, to: Date)
    case matchById(Int)
    case matchesByTeam(teamId: Int, from: Date?, to: Date?)
    case matchesByLeague(leagueId: Int, season: Int)
    case matchesByLeagueAndDate(leagueId: Int, date: Date)
    case apiStatus
    
    var path: String {
        switch self {
        case .apiStatus:
            return "/status"
        default:
            return "/fixtures"
        }
    }
    
    var queryItems: [URLQueryItem] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        switch self {
        case .liveMatches:
            return [URLQueryItem(name: "live", value: "all")]
            
        case .matchesByDate(let date):
            return [URLQueryItem(name: "date", value: dateFormatter.string(from: date))]
            
        case .matchesByDateRange(let from, let to):
            return [
                URLQueryItem(name: "from", value: dateFormatter.string(from: from)),
                URLQueryItem(name: "to", value: dateFormatter.string(from: to))
            ]
            
        case .matchById(let id):
            return [URLQueryItem(name: "id", value: "\(id)")]
            
        case .matchesByTeam(let teamId, let from, let to):
            var items = [URLQueryItem(name: "team", value: "\(teamId)")]
            if let from = from, let to = to {
                items.append(URLQueryItem(name: "from", value: dateFormatter.string(from: from)))
                items.append(URLQueryItem(name: "to", value: dateFormatter.string(from: to)))
            }
            return items
            
        case .matchesByLeague(let leagueId, let season):
            return [
                URLQueryItem(name: "league", value: "\(leagueId)"),
                URLQueryItem(name: "season", value: "\(season)")
            ]
            
        case .matchesByLeagueAndDate(let leagueId, let date):
            return [
                URLQueryItem(name: "league", value: "\(leagueId)"),
                URLQueryItem(name: "date", value: dateFormatter.string(from: date))
            ]
            
        case .apiStatus:
            return []
        }
    }
    
    func buildURL() -> URL? {
        let config = APIConfiguration.shared
        var components = URLComponents(string: config.baseURL + path)
        components?.queryItems = queryItems.isEmpty ? nil : queryItems
        return components?.url
    }
}
