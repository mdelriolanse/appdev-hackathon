//
//  PersistenceManager.swift
//  HackChallengeJournalApp
//
//  Created by Ethan Khan on 12/1/25.
//

import Foundation

class PersistenceManager {
    static let shared = PersistenceManager()
    private let entriesKey = "journalEntries"
    
    private init() {}
    
    func saveEntries(_ entries: [JournalEntry]) {
        if let encoded = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encoded, forKey: entriesKey)
        }
    }
    
    func loadEntries() -> [JournalEntry] {
        guard let data = UserDefaults.standard.data(forKey: entriesKey),
              let entries = try? JSONDecoder().decode([JournalEntry].self, from: data) else {
            return []
        }
        return entries.sorted { $0.date > $1.date }
    }
    
    func addEntry(_ entry: JournalEntry) {
        var entries = loadEntries()
        entries.append(entry)
        saveEntries(entries)
    }
}
