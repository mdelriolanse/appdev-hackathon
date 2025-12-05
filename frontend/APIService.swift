import Foundation

class APIService {
    static let shared = APIService()
    private let baseURL = "http://localhost:5000"
    
    private init() {}
    
    func classify(text: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/classify") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["text": text])
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ClassifyResponse.self, from: data)
        return response.category
    }
    
    func factCheck(text: String) async throws -> [Source] {
        guard let url = URL(string: "\(baseURL)/factcheck") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["text": text])
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(FactCheckResponse.self, from: data)
        return response.sources.map { Source(title: $0.title, url: $0.url) }
    }
}

struct ClassifyResponse: Codable {
    let category: String
}

struct FactCheckResponse: Codable {
    let sources: [SourceResponse]
}

struct SourceResponse: Codable {
    let title: String
    let url: String
}

enum APIError: Error {
    case invalidURL
    case networkError
}
