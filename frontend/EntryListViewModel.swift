import Foundation
import SwiftUI

@MainActor
class EntryListViewModel: ObservableObject {
    @Published var entries: [JournalEntry] = []
    @Published var searchText = ""
    @Published var selectedTab: Tab = .entries
    
    var filteredEntries: [JournalEntry] {
        if searchText.isEmpty {
            return entries
        }
        return entries.filter { entry in
            entry.title.localizedCaseInsensitiveContains(searchText) ||
            entry.content.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var categoryCounts: [String: Int] {
        Dictionary(grouping: entries.compactMap { $0.category }, by: { $0 })
            .mapValues { $0.count }
    }
    
    init() {
        loadEntries()
    }
    
    func loadEntries() {
        entries = PersistenceManager.shared.loadEntries()
    }
    
    func deleteEntry(_ entry: JournalEntry) {
        var allEntries = PersistenceManager.shared.loadEntries()
        allEntries.removeAll { $0.id == entry.id }
        PersistenceManager.shared.saveEntries(allEntries)
        loadEntries()
    }
}

enum Tab {
    case entries, categories
}
