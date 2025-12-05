import Foundation
import SwiftUI
import Combine

@MainActor
class EntryDetailViewModel: ObservableObject {
    @Published var entry: JournalEntry
    @Published var evidence: [Evidence] = []
    @Published var factCheckResults: [FactCheckResult] = []
    @Published var selectedText: String?
    @Published var isFactChecking = false
    @Published var isLoadingEvidence = false
    @Published var lastFactCheckResult: FactCheckResult?
    @Published var error: String?
    
    init(entry: JournalEntry) {
        self.entry = entry
    }
    
    func loadEvidence() async {
        isLoadingEvidence = true
        
        do {
            evidence = try await APIService.shared.getEvidence(entryId: entry.id)
        } catch {
            print("Failed to load evidence: \(error)")
        }
        
        isLoadingEvidence = false
    }
    
    func factCheck(_ claimText: String) async {
        isFactChecking = true
        selectedText = claimText
        error = nil
        
        do {
            let result = try await APIService.shared.factCheck(entryId: entry.id, claimText: claimText)
            lastFactCheckResult = result
            factCheckResults.append(result)
            
            // Reload evidence to include new results
            await loadEvidence()
        } catch {
            self.error = error.localizedDescription
            print("Fact check failed: \(error)")
        }
        
        isFactChecking = false
    }
    
    func clearSelection() {
        selectedText = nil
    }
}
