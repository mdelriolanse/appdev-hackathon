from fastapi import APIRouter, HTTPException, Request
import json
from typing import List, Optional
from exceptions import JournalEntryError, EntryCreationError, EntryNotFoundError
import db
from services.classification import classify_entry
from models import (
    JournalEntryRequest, 
    JournalEntryResponse, 
    CategoryResponse,
    EvidenceResponse
)

router = APIRouter(prefix="/journal", tags=["journal"])

DB = db.DataBaseDriver()


@router.post("/entry", response_model=JournalEntryResponse)
async def create_journal_entry(entry: JournalEntryRequest):
    """Create a new journal entry with automatic classification."""
    title = entry.title
    body = entry.body

    if not title or not body:
        raise HTTPException(status_code=400, detail="Title and body are required")

    try:
        classification = await classify_entry(title, body)

        if not classification or 'category' not in classification:
            raise HTTPException(status_code=400, detail="Failed to classify entry")

        response = DB.create_entry(title, body, [classification['category']])

        return JournalEntryResponse(**dict(response))
    
    except EntryCreationError as e:
        raise HTTPException(status_code=500, detail=str(e))
    except ValueError as e:
        raise HTTPException(status_code=502, detail=f"Classification failed: {str(e)}")
    except RuntimeError as e:
        raise HTTPException(status_code=502, detail=f"Classification service error: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error: {str(e)}")


@router.get("/entries", response_model=List[JournalEntryResponse])
async def get_all_journal_entries():
    """Get all journal entries."""
    entries = DB.get_all_entries()
    return entries


@router.get("/entry/{entry_id}", response_model=JournalEntryResponse)
async def get_journal_entry(entry_id: int):
    """Get a single journal entry by ID."""
    try:
        entry = DB.get_entry_by_id(entry_id)
        return entry
    except EntryNotFoundError:
        raise HTTPException(status_code=404, detail=f"Entry {entry_id} not found")


@router.get("/entry/{entry_id}/evidence", response_model=List[EvidenceResponse])
async def get_entry_evidence(entry_id: int):
    """Get all evidence records for a journal entry."""
    try:
        DB.get_entry_by_id(entry_id)
        evidence = DB.get_evidence_for_entry(entry_id)
        return evidence
    except EntryNotFoundError:
        raise HTTPException(status_code=404, detail=f"Entry {entry_id} not found")


@router.get("/categories", response_model=List[CategoryResponse])
async def get_all_categories():
    """Get all categories."""
    categories = DB.get_all_categories()
    return categories
