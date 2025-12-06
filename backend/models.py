from pydantic import BaseModel
from datetime import datetime
from typing import List, Optional


class JournalEntryRequest(BaseModel):
    title: str
    body: str


class JournalEntryResponse(BaseModel):
    id: int
    title: str
    body: str
    timestamp: datetime
    categories: List[str]


class EntryClassificationResponse(BaseModel):
    category: str


class CategoryResponse(BaseModel):
    id: int
    name: str


class EvidenceRequest(BaseModel):
    entry_id: int
    claim_text: str
    source_title: Optional[str] = None
    source_url: Optional[str] = None


class EvidenceResponse(BaseModel):
    id: int
    entry_id: int
    claim_text: str
    source_title: Optional[str]
    source_url: Optional[str]


class FactCheckRequest(BaseModel):
    entry_id: int
    claim_text: str


class FactCheckResponse(BaseModel):
    claim_text: str
    validity_score: int
    reasoning: str
    evidence: List[EvidenceResponse]
    source_count: int


class CoachRequest(BaseModel):
    title: str
    body: str


class CoachResponse(BaseModel):
    prompt: str