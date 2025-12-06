import Foundation

class APIService {
    static let shared = APIService()
    private let baseURL = "http://localhost:8000"
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        // Custom date formatter to handle timestamps without timezone (e.g., "2025-12-05T01:45:40.911727")
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try multiple formats
            let formats = [
                "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
                "yyyy-MM-dd'T'HH:mm:ss.SSS",
                "yyyy-MM-dd'T'HH:mm:ss",
                "yyyy-MM-dd'T'HH:mm:ssZ",
                "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            ]
            
            for format in formats {
                formatter.dateFormat = format
                if let date = formatter.date(from: dateString) {
                    return date
                }
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(dateString)")
        }
        return decoder
    }()
    
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    
    private init() {}
    
    // MARK: - Journal Entry CRUD
    
    /// Create a new journal entry (auto-classified by backend)
    func createEntry(title: String, body: String) async throws -> JournalEntry {
        guard let url = URL(string: "\(baseURL)/journal/entry") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = CreateEntryRequest(title: title, body: body)
        request.httpBody = try encoder.encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        
        return try decoder.decode(JournalEntry.self, from: data)
    }
    
    /// Get all journal entries
    func getAllEntries() async throws -> [JournalEntry] {
        guard let url = URL(string: "\(baseURL)/journal/entries") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        try validateResponse(response)
        
        // Debug: print raw JSON
        if let jsonString = String(data: data, encoding: .utf8) {
            print("[APIService] Raw entries JSON: \(jsonString)")
        }
        
        do {
            let entries = try decoder.decode([JournalEntry].self, from: data)
            print("[APIService] Successfully decoded \(entries.count) entries")
            return entries
        } catch {
            print("[APIService] Decoding error: \(error)")
            throw APIError.decodingError(error)
        }
    }
    
    /// Get a single journal entry by ID
    func getEntry(id: Int) async throws -> JournalEntry {
        guard let url = URL(string: "\(baseURL)/journal/entry/\(id)") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        try validateResponse(response)
        
        return try decoder.decode(JournalEntry.self, from: data)
    }
    
    /// Get evidence for a journal entry
    func getEvidence(entryId: Int) async throws -> [Evidence] {
        guard let url = URL(string: "\(baseURL)/journal/entry/\(entryId)/evidence") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        try validateResponse(response)
        
        return try decoder.decode([Evidence].self, from: data)
    }
    
    // MARK: - Categories
    
    /// Get all categories
    func getAllCategories() async throws -> [Category] {
        guard let url = URL(string: "\(baseURL)/journal/categories") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        try validateResponse(response)
        
        return try decoder.decode([Category].self, from: data)
    }
    
    // MARK: - Fact Check
    
    /// Fact-check a claim from a journal entry
    func factCheck(entryId: Int, claimText: String) async throws -> FactCheckResult {
        guard let url = URL(string: "\(baseURL)/factcheck") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = FactCheckRequest(entryId: entryId, claimText: claimText)
        request.httpBody = try encoder.encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        
        return try decoder.decode(FactCheckResult.self, from: data)
    }
    
    // MARK: - Journaling Coach
    
    /// Get a journaling coach prompt based on the current entry
    func getCoachPrompt(title: String, body: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/coach") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = CoachRequest(title: title, body: body)
        request.httpBody = try encoder.encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        
        let coachResponse = try decoder.decode(CoachResponse.self, from: data)
        return coachResponse.prompt
    }
    
    // MARK: - Helpers
    
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return
        case 400:
            throw APIError.badRequest
        case 404:
            throw APIError.notFound
        case 500...599:
            throw APIError.serverError
        default:
            throw APIError.unknown(httpResponse.statusCode)
        }
    }
    
    private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            try validateResponse(response)
            return try decoder.decode(T.self, from: data)
        } catch let error as URLError {
            throw APIError.networkError(error)
        } catch let error as DecodingError {
            throw APIError.decodingError(error)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    private func performRequest<T: Decodable>(from url: URL) async throws -> T {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            try validateResponse(response)
            return try decoder.decode(T.self, from: data)
        } catch let error as URLError {
            throw APIError.networkError(error)
        } catch let error as DecodingError {
            throw APIError.decodingError(error)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
}

// MARK: - API Errors

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case badRequest
    case notFound
    case serverError
    case networkError(Error)
    case decodingError(Error)
    case unknown(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .badRequest:
            return "Bad request"
        case .notFound:
            return "Resource not found"
        case .serverError:
            return "Server error"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to parse response: \(error.localizedDescription)"
        case .unknown(let code):
            return "Unknown error (code: \(code))"
        }
    }
}
