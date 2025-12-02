from tokenize import StopTokenizing
from pydantic import BaseModel
from datetime import datetime

class JournalEntryRequest(BaseModel):
    title: str
    body: str

class JournalEntryResponse(BaseModel):
    id: str
    title: str
    body: str
    date: datetime
    category: str
    # favicon: 

class EntryClassificationResponse(BaseModel):
    category: str

    # add validator to ensure that lenght of category is no more than one word.