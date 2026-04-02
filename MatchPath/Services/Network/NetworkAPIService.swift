import Foundation
import Combine

protocol NetworkAPIServiceProtocol {
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T
}

class NetworkAPIService: NetworkAPIServiceProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder
    
    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
        
        // Configure decoder for API-Football date format
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        self.decoder.dateDecodingStrategy = .formatted(dateFormatter)
    }
    
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        guard let url = endpoint.buildURL() else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        
        // Add headers from configuration
        for (key, value) in APIConfiguration.shared.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        #if DEBUG
        print("🌐 API Request: \(url.absoluteString)")
        #endif
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            #if DEBUG
            print("📡 Response Status: \(httpResponse.statusCode)")
            #endif
            
            switch httpResponse.statusCode {
            case 200...299:
                do {
                    let decoded = try decoder.decode(T.self, from: data)
                    return decoded
                } catch {
                    #if DEBUG
                    print("❌ Decoding error: \(error)")
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("📄 Response data: \(jsonString.prefix(500))")
                    }
                    #endif
                    throw APIError.decodingError(error)
                }
                
            case 401:
                throw APIError.unauthorized
                
            case 429:
                throw APIError.rateLimitExceeded
                
            case 500...599:
                throw APIError.serverError(httpResponse.statusCode)
                
            default:
                throw APIError.httpError(httpResponse.statusCode)
            }
            
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
}

// MARK: - Combine Support

extension NetworkAPIService {
    func requestPublisher<T: Decodable>(_ endpoint: APIEndpoint) -> AnyPublisher<T, Error> {
        Future { promise in
            Task {
                do {
                    let result: T = try await self.request(endpoint)
                    promise(.success(result))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
