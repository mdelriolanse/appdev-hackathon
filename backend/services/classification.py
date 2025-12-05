import os
import json
import logging
from models import EntryClassificationResponse
from typing import List, Dict
from anthropic import AsyncAnthropic
from dotenv import load_dotenv
import db

load_dotenv()

logger = logging.getLogger(__name__)

# Initialize Claude async client
ANTHROPIC_API_KEY = os.getenv("ANTHROPIC_API_KEY")
logger.info(f"[classification] ANTHROPIC_API_KEY loaded: {'Yes' if ANTHROPIC_API_KEY else 'NO - MISSING!'}")
if not ANTHROPIC_API_KEY:
    raise ValueError("ANTHROPIC_API_KEY environment variable is required")

client = AsyncAnthropic(api_key=ANTHROPIC_API_KEY)
MODEL = "claude-sonnet-4-20250514"
logger.info(f"[classification] Using model: {MODEL}")

DB = db.DataBaseDriver()


async def classify_entry(title: str, body: str) -> EntryClassificationResponse:
    """
    Have Claude classify category of a journal.
    Each call fetches current categories in the database, and asks Claude to attempt to use one of those if well-suited enough.
    
    Args:
        title: brief string with title of entry.
        body: full body of journal entry.
    
    Returns:
        Dictionary with 'category' containing a single word that best suits the content of the entry.
    """
    logger.info(f"[classify_entry] Starting classification for title: {title[:50]}...")
    
    # Fetch existing categories from database
    logger.debug("[classify_entry] Fetching existing categories from database")
    existing_categories = DB.get_all_categories()
    category_names = [cat['name'] for cat in existing_categories]
    logger.info(f"[classify_entry] Found {len(category_names)} existing categories: {category_names}")
    
    # Build the prompt with existing categories
    if category_names:
        existing_cats_str = ", ".join(category_names)
        category_instruction = f"""EXISTING CATEGORIES in the database: [{existing_cats_str}]

IMPORTANT: If any of the existing categories above is a good fit for this entry, you MUST use it exactly as written.
Only create a new category if none of the existing ones are relevant."""
    else:
        category_instruction = "No existing categories in the database yet. Create an appropriate single-word category."
    
    prompt = f"""You are classifying a journal entry into a category.

Title: {title}

Body:
{body}

{category_instruction}

Analyze the content and determine the most appropriate single-word category that best describes this journal entry.
If creating a new category, use lowercase single words like: personal, work, health, travel, food, fitness, relationships, finance, creative, gratitude, goals, reflection, etc.

Return JSON only: {{"category": "..."}}"""

    try:
        logger.info(f"[classify_entry] Calling Claude API with model: {MODEL}")
        message = await client.messages.create(
            model=MODEL,
            max_tokens=256,
            messages=[
                {
                    "role": "user",
                    "content": prompt
                }
            ]
        )
        logger.info(f"[classify_entry] Claude API call successful. Stop reason: {message.stop_reason}")
        logger.debug(f"[classify_entry] Full message object: {message}")
        
        # Extract text from response
        logger.debug(f"[classify_entry] Message content: {message.content}")
        response_text = message.content[0].text.strip()
        logger.info(f"[classify_entry] Raw response text: {response_text}")
        
        # Try to parse JSON from the response
        # Claude might wrap JSON in markdown code blocks
        if "```json" in response_text:
            logger.debug("[classify_entry] Stripping ```json markdown wrapper")
            response_text = response_text.split("```json")[1].split("```")[0].strip()
        elif "```" in response_text:
            logger.debug("[classify_entry] Stripping ``` markdown wrapper")
            response_text = response_text.split("```")[1].split("```")[0].strip()
        
        logger.debug(f"[classify_entry] Cleaned response text for JSON parsing: {response_text}")
        result = json.loads(response_text)
        logger.info(f"[classify_entry] Parsed JSON result: {result}")
        
        # Validate structure
        if 'category' not in result:
            logger.error(f"[classify_entry] Missing 'category' field in result: {result}")
            raise ValueError("Missing 'category' field in Claude response")
        
        # Normalize to lowercase
        result['category'] = result['category'].lower()
        logger.info(f"[classify_entry] Final category: {result['category']}")
        
        return result
        
    except json.JSONDecodeError as e:
        logger.error(f"[classify_entry] JSON decode error: {e}. Response was: {response_text}")
        raise ValueError(f"Failed to parse JSON from Claude response: {e}")
    except Exception as e:
        logger.exception(f"[classify_entry] Unexpected error during Claude API call: {e}")
        raise RuntimeError(f"Claude API error: {e}")
