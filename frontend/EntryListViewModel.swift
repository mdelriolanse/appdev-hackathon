import Foundation
import SwiftUI
import Combine

@MainActor
class EntryListViewModel: ObservableObject {
    @Published var entries: [JournalEntry] = []
    @Published var categories: [Category] = []
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var error: String?
    
    var filteredEntries: [JournalEntry] {
        if searchText.isEmpty {
            return entries
        }
        return entries.filter { entry in
            entry.title.localizedCaseInsensitiveContains(searchText) ||
            entry.body.localizedCaseInsensitiveContains(searchText) ||
            entry.categories.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var categoryCounts: [String: Int] {
        var counts: [String: Int] = [:]
        for entry in entries {
            for category in entry.categories {
                counts[category, default: 0] += 1
            }
        }
        return counts
    }
    
    init() {
        // Load cached entries first for instant display
        entries = PersistenceManager.shared.loadCachedEntries()
    }
    
    func loadEntries() async {
        isLoading = true
        error = nil
        
        do {
            let fetchedEntries = try await APIService.shared.getAllEntries()
            entries = fetchedEntries.sorted { $0.timestamp > $1.timestamp }
            
            // Update cache on successful fetch
            PersistenceManager.shared.cacheEntries(entries)
            error = nil
        } catch let apiError as APIError {
            // User-friendly error messages
            switch apiError {
            case .networkError:
                self.error = "Unable to connect. Showing cached entries."
            case .serverError:
                self.error = "Server error. Please try again later."
            default:
                self.error = apiError.localizedDescription
            }
            print("Failed to load entries: \(apiError)")
            
            // Fall back to cached entries
            let cached = PersistenceManager.shared.loadCachedEntries()
            if !cached.isEmpty {
                entries = cached
            }
        } catch {
            self.error = "Something went wrong. Showing cached entries."
            print("Failed to load entries: \(error)")
            
            let cached = PersistenceManager.shared.loadCachedEntries()
            if !cached.isEmpty {
                entries = cached
            }
        }
        
        isLoading = false
    }
    
    func loadCategories() async {
        do {
            categories = try await APIService.shared.getAllCategories()
        } catch {
            print("Failed to load categories: \(error)")
        }
    }
    
    func deleteEntry(_ entry: JournalEntry) {
        // Remove from local list immediately for responsive UI
        entries.removeAll { $0.id == entry.id }
        PersistenceManager.shared.cacheEntries(entries)
        
        // Note: Backend doesn't have delete endpoint yet
        // When added, call APIService.shared.deleteEntry(id: entry.id)
    }
    
    func refreshEntries() {
        Task {
            await loadEntries()
        }
    }
}

enum Tab: Hashable {
    case home, categories
}
