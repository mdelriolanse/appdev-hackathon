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
    
    private var lastBodyLength: Int = 0
    
    init(title: String = "", body: String = "") {
        self.title = title
        self.body = body
        self.lastBodyLength = body.count
    }
    
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
    
    func handleBodyChange(_ newValue: String) {
        let newLength = newValue.count
        let isInsertion = newLength > lastBodyLength
        lastBodyLength = newLength
        
        // Only trigger smart list logic if we just added text (avoid triggering on backspace)
        guard isInsertion else { return }
        
        // Detect if the user just pressed Enter (newline added)
        guard newValue.hasSuffix("\n") else { return }
        
        // Get the last non-empty line (the one just typed before the newline)
        let lines = newValue.split(separator: "\n", omittingEmptySubsequences: false)
        guard lines.count >= 2 else { return }
        
        let previousLine = String(lines[lines.count - 2])
        
        // Check for numbered list pattern (e.g., "1. ")
        if let range = previousLine.range(of: "^\\d+\\. ", options: .regularExpression) {
            let prefix = String(previousLine[range])
            let numberString = prefix.dropLast(2) // remove ". "
            if let number = Int(numberString) {
                // Append next number
                let nextString = "\(number + 1). "
                self.body += nextString
                self.lastBodyLength += nextString.count // Update length so we don't think it's another insertion
            }
        }
        // Check for bullet list pattern (e.g., "- ")
        else if previousLine.trimmingCharacters(in: .whitespaces).starts(with: "- ") {
            let nextString = "- "
            self.body += nextString
            self.lastBodyLength += nextString.count
        }
    }
    
    func reset() {
        title = ""
        body = ""
        error = nil
        savedEntry = nil
    }
}
