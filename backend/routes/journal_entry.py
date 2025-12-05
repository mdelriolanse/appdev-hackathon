from fastapi import APIRouter, HTTPException, Request
import json
import logging
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

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/journal", tags=["journal"])

DB = db.DataBaseDriver()


@router.post("/entry", response_model=JournalEntryResponse)
async def create_journal_entry(entry: JournalEntryRequest):
    """Create a new journal entry with automatic classification."""
    logger.info(f"[POST /entry] Received request to create journal entry")
    title = entry.title
    body = entry.body
    logger.debug(f"[POST /entry] Title: {title[:50]}..., Body length: {len(body)}")

    if not title or not body:
        logger.warning("[POST /entry] Missing title or body in request")
        raise HTTPException(status_code=400, detail="Title and body are required")

    try:
        # Classify the entry using Claude
        logger.info("[POST /entry] Calling classify_entry...")
        classification = await classify_entry(title, body)
        logger.info(f"[POST /entry] Classification result: {classification}")

        if not classification or 'category' not in classification:
            logger.error(f"[POST /entry] Invalid classification result: {classification}")
            raise HTTPException(status_code=400, detail="Failed to classify entry")

        # Create entry with category as a list
        logger.info(f"[POST /entry] Creating entry in database with category: {classification['category']}")
        response = DB.create_entry(title, body, [classification['category']])
        logger.info(f"[POST /entry] Entry created successfully with id: {response.get('id')}")

        return JournalEntryResponse(**dict(response))
    
    except EntryCreationError as e:
        logger.error(f"[POST /entry] EntryCreationError: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    except ValueError as e:
        # Claude JSON parsing error
        logger.error(f"[POST /entry] ValueError (JSON parsing): {e}")
        raise HTTPException(status_code=502, detail=f"Classification failed: {str(e)}")
    except RuntimeError as e:
        # Claude API error
        logger.error(f"[POST /entry] RuntimeError (Claude API): {e}")
        raise HTTPException(status_code=502, detail=f"Classification service error: {str(e)}")
    except Exception as e:
        # Catch-all for unexpected errors
        logger.exception(f"[POST /entry] Unexpected error: {e}")
        raise HTTPException(status_code=500, detail=f"Unexpected error: {str(e)}")


@router.get("/entries", response_model=List[JournalEntryResponse])
async def get_all_journal_entries():
    """Get all journal entries."""
    logger.info("[GET /entries] Fetching all journal entries")
    entries = DB.get_all_entries()
    logger.info(f"[GET /entries] Returning {len(entries)} entries")
    return entries


@router.get("/entry/{entry_id}", response_model=JournalEntryResponse)
async def get_journal_entry(entry_id: int):
    """Get a single journal entry by ID."""
    logger.info(f"[GET /entry/{entry_id}] Fetching entry")
    try:
        entry = DB.get_entry_by_id(entry_id)
        logger.info(f"[GET /entry/{entry_id}] Found entry: {entry.get('title', 'N/A')}")
        return entry
    except EntryNotFoundError:
        logger.warning(f"[GET /entry/{entry_id}] Entry not found")
        raise HTTPException(status_code=404, detail=f"Entry {entry_id} not found")


@router.get("/entry/{entry_id}/evidence", response_model=List[EvidenceResponse])
async def get_entry_evidence(entry_id: int):
    """Get all evidence records for a journal entry."""
    logger.info(f"[GET /entry/{entry_id}/evidence] Fetching evidence")
    try:
        # Verify entry exists
        DB.get_entry_by_id(entry_id)
        evidence = DB.get_evidence_for_entry(entry_id)
        logger.info(f"[GET /entry/{entry_id}/evidence] Returning {len(evidence)} evidence records")
        return evidence
    except EntryNotFoundError:
        logger.warning(f"[GET /entry/{entry_id}/evidence] Entry not found")
        raise HTTPException(status_code=404, detail=f"Entry {entry_id} not found")


@router.get("/categories", response_model=List[CategoryResponse])
async def get_all_categories():
    """Get all categories."""
    logger.info("[GET /categories] Fetching all categories")
    categories = DB.get_all_categories()
    logger.info(f"[GET /categories] Returning {len(categories)} categories")
    return categories
