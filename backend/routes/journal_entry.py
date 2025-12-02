from fastapi import APIRouter, HTTPException, Request
import json
from typing import List, Optional
from exceptions import JournalEntryError, EntryCreationError
import db
from models import JournalEntryRequest, JournalEntryResponse

router = APIRouter(prefix="/journal-entry", tags=["journal-entry"])

DB =  db.DataBaseDriver()

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
        # category = await classify_entry(entry.body)
        #removed category for testing purposes, later on just add it 
        response = DB.create_entry(title, body)

        return JournalEntryResponse(**response)
    
    except EntryCreationError:
        raise HTTPException(status_code=500, detail="Failed to save entry")
        


@router.get("",response_model=list[JournalEntryResponse])
async def get_all_journal_entries():
    return DB.get_all_entries()