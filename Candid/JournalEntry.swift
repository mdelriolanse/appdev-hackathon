import Foundation

// MARK: - Journal Entry

struct JournalEntry: Codable, Identifiable {
    let id: Int
    var title: String
    var body: String
    let timestamp: Date
    var categories: [String]
    
    // For local display of fact checks (fetched separately)
    var factCheckResults: [FactCheckResult]?
    
    enum CodingKeys: String, CodingKey {
        case id, title, body, timestamp, categories
    }
    
    // Convenience for display
    var primaryCategory: String? {
        categories.first
    }
    
    var date: Date {
        timestamp
    }
}

// MARK: - Category

struct Category: Codable, Identifiable {
    let id: Int
    let name: String
}

// MARK: - Evidence

struct Evidence: Codable, Identifiable {
    let id: Int
    let entryId: Int
    let claimText: String
    let sourceTitle: String?
    let sourceUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case entryId = "entry_id"
        case claimText = "claim_text"
        case sourceTitle = "source_title"
        case sourceUrl = "source_url"
    }
}

// MARK: - Fact Check Result

struct FactCheckResult: Codable, Identifiable {
    var id: String { claimText }
    let claimText: String
    let validityScore: Int
    let reasoning: String
    let evidence: [Evidence]
    let sourceCount: Int
    
    enum CodingKeys: String, CodingKey {
        case claimText = "claim_text"
        case validityScore = "validity_score"
        case reasoning
        case evidence
        case sourceCount = "source_count"
    }
}

// MARK: - API Request Models

struct CreateEntryRequest: Codable {
    let title: String
    let body: String
}

struct FactCheckRequest: Codable {
    let entryId: Int
    let claimText: String
    
    enum CodingKeys: String, CodingKey {
        case entryId = "entry_id"
        case claimText = "claim_text"
    }
}

struct CoachRequest: Codable {
    let title: String
    let body: String
}

struct CoachResponse: Codable {
    let prompt: String
}