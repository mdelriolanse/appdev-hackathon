# backend/exceptions.py
class JournalEntryError(Exception):
    """Base exception for journal entry operations"""
    pass

class EntryNotFoundError(JournalEntryError):
    """Raised when a journal entry is not found"""
    pass

class EntryValidationError(JournalEntryError):
    """Raised when entry validation fails"""
    pass

class ClassificationError(JournalEntryError):
    """Raised when classification fails"""
    pass

class EntryCreationError(JournalEntryError):
    """Raised when entry creation fails"""
    pass