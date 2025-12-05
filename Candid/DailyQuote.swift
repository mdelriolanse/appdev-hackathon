import Foundation

struct DailyQuote {
    static let quotes = [
        "The unexamined life is not worth living. — Socrates",
        "Write what should not be forgotten. — Isabel Allende",
        "We write to taste life twice. — Anaïs Nin",
        "Fill your paper with the breathings of your heart. — William Wordsworth",
        "Writing is thinking on paper. — William Zinsser",
        "The purpose of a writer is to keep civilization from destroying itself. — Albert Camus",
        "To write is human, to edit is divine. — Stephen King",
        "Writing is the painting of the voice. — Voltaire"
    ]
    
    static func getTodaysQuote() -> String {
        let day = Calendar.current.component(.day, from: Date())
        return quotes[day % quotes.count]
    }
}
