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
        "Writing is the painting of the voice. — Voltaire",
        "Start writing, no matter what. The water does not flow until the faucet is turned on. — Louis L'Amour",
        "You can make anything by writing. — C.S. Lewis",
        "The scariest moment is always just before you start. — Stephen King",
        "Don't tell me the moon is shining; show me the glint of light on broken glass. — Anton Chekhov",
        "There is no greater agony than bearing an untold story inside you. — Maya Angelou",
        "I write to discover what I know. — Flannery O'Connor",
        "Words are a lens to focus one’s mind. — Ayn Rand",
        "A word after a word after a word is power. — Margaret Atwood",
        "Tears are words that need to be written. — Paulo Coelho",
        "Writing is an act of faith, not a trick of grammar. — E.B. White",
        "Your intuition knows what to write, so get out of the way. — Ray Bradbury",
        "One day I will find the right words, and they will be simple. — Jack Kerouac",
        "The art of writing is the art of discovering what you believe. — Gustave Flaubert",
        "Every secret of a writer’s soul, every experience of his life, every quality of his mind, is written large in his works. — Virginia Woolf",
        "If there's a book that you want to read, but it hasn't been written yet, then you must write it. — Toni Morrison"
    ]
    
    static func getTodaysQuote() -> String {
        // Return a random quote every time
        return quotes.randomElement() ?? "Write your story."
    }
}
