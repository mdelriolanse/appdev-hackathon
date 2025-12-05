import Foundation
import SwiftUI

@MainActor
class NewEntryViewModel: ObservableObject {
    @Published var title = ""
    @Published var content = ""
    @Published var isClassifying = false
    
    func saveEntry() async {
        guard !title.isEmpty, !content.isEmpty else { return }
        
        isClassifying = true
        var category: String?
        
        do {
            category = try await APIService.shared.classify(text: content)
        } catch {
            print("Classification failed: \(error)")
        }
        
        isClassifying = false
        
        let entry = JournalEntry(title: title, content: content, category: category)
        PersistenceManager.shared.addEntry(entry)
    }
}
