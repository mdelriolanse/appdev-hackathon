from fastapi import APIRouter, HTTPException
from typing import List
from exceptions import JournalEntryError, EntryNotFoundError
import db
from services.factcheck import factcheck_claim
from models import FactCheckRequest, FactCheckResponse, EvidenceResponse

router = APIRouter(prefix="/factcheck", tags=["factcheck"])

DB = db.DataBaseDriver()


@router.post("", response_model=FactCheckResponse)
async def fact_check_claim(request: FactCheckRequest):
    """
    Fact-check a claim from a journal entry.
    
    Uses a 3-step pipeline:
    1. Extract core verifiable claim using Claude
    2. Search for evidence using Tavily API
    3. Analyze and score using Claude
    
    Stores the sources as evidence records tied to the entry.
    """
    entry_id = request.entry_id
    claim_text = request.claim_text

    if not claim_text or not claim_text.strip():
        raise HTTPException(status_code=400, detail="claim_text is required")

    # Verify entry exists
    try:
        DB.get_entry_by_id(entry_id)
    except EntryNotFoundError:
        raise HTTPException(status_code=404, detail=f"Entry {entry_id} not found")

    try:
        # Run the fact-checking pipeline (synchronous)
        verdict = factcheck_claim(claim_text)

        # Store evidence in database
        evidence_records = []
        for source in verdict.sources:
            evidence = DB.create_evidence(
                entry_id=entry_id,
                claim_text=claim_text,
                source_title=source.get('source_title'),
                source_url=source.get('source_url')
            )
            evidence_records.append(EvidenceResponse(**dict(evidence)))

        return FactCheckResponse(
            claim_text=claim_text,
            validity_score=verdict.validity_score,
            reasoning=verdict.reasoning,
            evidence=evidence_records,
            source_count=verdict.source_count
        )

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except JournalEntryError as e:
        raise HTTPException(status_code=500, detail=str(e))
    except RuntimeError as e:
        raise HTTPException(status_code=500, detail=str(e))
