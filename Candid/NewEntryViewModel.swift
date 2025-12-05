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
        
        // Check for numbered list pattern (e.g., "1. " or "  1. ")
        // Regex: Start, optional whitespace (captured), digits (captured), dot, whitespace
        // Using manual parsing for simplicity and safety without NSRegularExpression boilerplate
        if let dotIndex = previousLine.firstIndex(of: ".") {
            let prefix = previousLine[..<dotIndex] // "  1"
            let trimmedPrefix = prefix.trimmingCharacters(in: .whitespaces) // "1"
            
            // Check if it's a number
            if let number = Int(trimmedPrefix), number >= 0 {
                // Check if followed by space
                let afterDotIndex = previousLine.index(after: dotIndex)
                if afterDotIndex < previousLine.endIndex, previousLine[afterDotIndex].isWhitespace {
                    // It is a numbered list!
                    
                    // Extract indentation
                    let indentation = previousLine.prefix(while: { $0.isWhitespace })
                    
                    let nextString = "\(indentation)\(number + 1). "
                    self.body += nextString
                    self.lastBodyLength += nextString.count
                    return
                }
            }
        }
        
        // Check for bullet list pattern (e.g., "- ")
        if previousLine.trimmingCharacters(in: .whitespaces).starts(with: "- ") {
            let indentation = previousLine.prefix(while: { $0.isWhitespace })
            let nextString = "\(indentation)- "
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
