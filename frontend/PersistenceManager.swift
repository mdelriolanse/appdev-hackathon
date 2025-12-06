import Foundation

/// Cache layer for offline access to journal entries
class PersistenceManager {
    static let shared = PersistenceManager()
    private let entriesKey = "cachedJournalEntries"
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    
    private init() {}
    
    // MARK: - Cache Operations
    
    func cacheEntries(_ entries: [JournalEntry]) {
        if let encoded = try? encoder.encode(entries) {
            UserDefaults.standard.set(encoded, forKey: entriesKey)
        }
    }
    
    func loadCachedEntries() -> [JournalEntry] {
        guard let data = UserDefaults.standard.data(forKey: entriesKey),
              let entries = try? decoder.decode([JournalEntry].self, from: data) else {
            return []
        }
        return entries.sorted { $0.timestamp > $1.timestamp }
    }
    
    func cacheEntry(_ entry: JournalEntry) {
        var entries = loadCachedEntries()
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index] = entry
        } else {
            entries.insert(entry, at: 0)
        }
        cacheEntries(entries)
    }
    
    func removeCachedEntry(id: Int) {
        var entries = loadCachedEntries()
        entries.removeAll { $0.id == id }
        cacheEntries(entries)
    }
    
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: entriesKey)
    }
}
