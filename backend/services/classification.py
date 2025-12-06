import os
import json
from models import EntryClassificationResponse
from typing import List, Dict
from anthropic import AsyncAnthropic
from dotenv import load_dotenv
import db

load_dotenv()

ANTHROPIC_API_KEY = os.getenv("ANTHROPIC_API_KEY")
if not ANTHROPIC_API_KEY:
    raise ValueError("ANTHROPIC_API_KEY environment variable is required")

client = AsyncAnthropic(api_key=ANTHROPIC_API_KEY)
MODEL = "claude-sonnet-4-20250514"

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
    existing_categories = DB.get_all_categories()
    category_names = [cat['name'] for cat in existing_categories]
    
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
        
        response_text = message.content[0].text.strip()
        
        if "```json" in response_text:
            response_text = response_text.split("```json")[1].split("```")[0].strip()
        elif "```" in response_text:
            response_text = response_text.split("```")[1].split("```")[0].strip()
        
        result = json.loads(response_text)
        
        if 'category' not in result:
            raise ValueError("Missing 'category' field in Claude response")
        
        result['category'] = result['category'].lower()
        
        return result
        
    except json.JSONDecodeError as e:
        raise ValueError(f"Failed to parse JSON from Claude response: {e}")
    except Exception as e:
        raise RuntimeError(f"Claude API error: {e}")
