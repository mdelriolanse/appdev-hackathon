from fastapi import APIRouter, HTTPException, Request
import json
from typing import List, Optional
from backend.exceptions import JournalEntryError, EntryCreationError
import db
from models import JournalEntryRequest, JournalEntryResponse

router = APIRouter(prefix="/journal-entry", tags=["journal-entry"])

@router.post("", response_model=JournalEntryResponse)
async def create_journal_entry(entry: JournalEntryRequest):
    title = entry.title
    body = entry.body

    if not title or not body:
        raise HTTPException(status_code=400, detail=f"""
            Malformed request: Expected strings in title and body fields, got {
                json.dumps(entry)
            }
        )""")

    try:
        # run classification pipeline
        category = await classify_entry(entry.body)

        response = db.create_entry(title, body, category)

        return JournalEntryResponse(**response)
    
    except EntryCreationError:
        raise HTTPException(status_code=500, detail="Failed to save entry")
        


