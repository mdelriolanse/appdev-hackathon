import os
import json
from models import EntryClassificationResponse
from typing import List, Dict
from anthropic import Anthropic
from dotenv import load_dotenv
load_dotenv()

# Initialize Claude client
ANTHROPIC_API_KEY = os.getenv("ANTHROPIC_API_KEY")
if not ANTHROPIC_API_KEY:
    raise ValueError("ANTHROPIC_API_KEY environment variable is required")

client = Anthropic(api_key=ANTHROPIC_API_KEY)
MODEL = "claude-sonnet-4-20250514"

def classify_entry(title: str, body: str) -> EntryClassificationResponse:
    """
    Have Claude classify category of a journal.
    Each call fetches current categories in the database, and asks Claude to attempt to use of those if well-suited enough.
    
    Args:
        title: brief string with title of entry.
        body: full body of journal entry.
    
    Returns:
        Dictionary with 'category' containing a single word that best suits the content of the entry.
    """

    
    prompt = f"""You are analyzing a debate on: {question}

PRO arguments:
{pro_text}

CON arguments:
{con_text}

Generate three things (do NOT create new arguments, only synthesize existing):
1. OVERALL SUMMARY (2-3 paragraphs): What is this debate about? Main themes?
2. CONSENSUS VIEW (1-2 paragraphs): What do both sides agree on?
3. TIMELINE VIEW: Chronological narrative based on arguments. Array of {{"period": "...", "description": "..."}}

Return JSON only: {{"overall_summary": "...", "consensus_view": "...", "timeline_view": [...]}}"""

    try:
        message = client.messages.create(
            model=MODEL,
            max_tokens=4096,
            messages=[
                {
                    "role": "user",
                    "content": prompt
                }
            ]
        )
        
        # Extract text from response
        response_text = message.content[0].text.strip()
        
        # Try to parse JSON from the response
        # Claude might wrap JSON in markdown code blocks
        if "```json" in response_text:
            response_text = response_text.split("```json")[1].split("```")[0].strip()
        elif "```" in response_text:
            response_text = response_text.split("```")[1].split("```")[0].strip()
        
        result = json.loads(response_text)
        
        # Validate structure
        if not all(key in result for key in ['overall_summary', 'consensus_view', 'timeline_view']):
            raise ValueError("Missing required fields in Claude response")
        
        if not isinstance(result['timeline_view'], list):
            raise ValueError("timeline_view must be a list")
        
        return result
        
    except json.JSONDecodeError as e:
        raise ValueError(f"Failed to parse JSON from Claude response: {e}")
    except Exception as e:
        raise RuntimeError(f"Claude API error: {e}")