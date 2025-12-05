import Foundation
import SwiftUI

@MainActor
class EntryDetailViewModel: ObservableObject {
    @Published var entry: JournalEntry
    @Published var selectedText: String?
    @Published var isFactChecking = false
    @Published var showingFactCheck = false
    
    init(entry: JournalEntry) {
        self.entry = entry
    }
    
    func factCheck(_ text: String) async {
        isFactChecking = true
        selectedText = text
        
        do {
            let sources = try await APIService.shared.factCheck(text: text)
            let factCheck = FactCheck(text: text, sources: sources)
            entry.factChecks.append(factCheck)
            PersistenceManager.shared.updateEntry(entry)
            showingFactCheck = true
        } catch {
            print("Fact check failed: \(error)")
        }
        
        isFactChecking = false
    }
}
