import Foundation

struct JournalEntry: Codable, Identifiable {
    let id: String
    var title: String
    var content: String
    let date: Date
    var category: String?
    var factChecks: [FactCheck]
    
    init(title: String, content: String, category: String? = nil) {
        self.id = UUID().uuidString
        self.title = title
        self.content = content
        self.date = Date()
        self.category = category
        self.factChecks = []
    }
}

struct FactCheck: Codable, Identifiable {
    let id: String
    let text: String
    let sources: [Source]
    let date: Date
    
    init(text: String, sources: [Source]) {
        self.id = UUID().uuidString
        self.text = text
        self.sources = sources
        self.date = Date()
    }
}

struct Source: Codable, Identifiable {
    let id: String
    let title: String
    let url: String
    
    init(title: String, url: String) {
        self.id = UUID().uuidString
        self.title = title
        self.url = url
    }
}
