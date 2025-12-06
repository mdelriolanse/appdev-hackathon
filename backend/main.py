from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
import db
from routes import journal_entry, factcheck, coach
import uvicorn

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(journal_entry.router)
app.include_router(factcheck.router)
app.include_router(coach.router)

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)