import Foundation
import SwiftUI
import Combine

@MainActor
class NewEntryViewModel: ObservableObject {
    @Published var title = ""
    @Published var body = ""
    @Published var isSaving = false
    @Published var error: String?
    @Published var savedEntry: JournalEntry?
    
    func saveEntry() async -> JournalEntry? {
        guard !title.isEmpty, !body.isEmpty else { return nil }
        
        isSaving = true
        error = nil
        
        do {
            // Backend auto-classifies the entry
            let entry = try await APIService.shared.createEntry(title: title, body: body)
            savedEntry = entry
            
            // Cache locally for offline access
            PersistenceManager.shared.cacheEntry(entry)
            
            isSaving = false
            return entry
        } catch {
            self.error = error.localizedDescription
            print("Failed to create entry: \(error)")
            isSaving = false
            return nil
        }
    }
    
    func reset() {
        title = ""
        body = ""
        error = nil
        savedEntry = nil
    }
}
