import os
import json
import logging
from typing import Dict
from anthropic import AsyncAnthropic
from dotenv import load_dotenv

load_dotenv()

logger = logging.getLogger(__name__)

# Initialize Claude async client
ANTHROPIC_API_KEY = os.getenv("ANTHROPIC_API_KEY")
logger.info(f"[coach] ANTHROPIC_API_KEY loaded: {'Yes' if ANTHROPIC_API_KEY else 'NO - MISSING!'}")
if not ANTHROPIC_API_KEY:
    raise ValueError("ANTHROPIC_API_KEY environment variable is required")

client = AsyncAnthropic(api_key=ANTHROPIC_API_KEY)
MODEL = "claude-sonnet-4-20250514"
logger.info(f"[coach] Using model: {MODEL}")


async def coach_prompt(title: str, body: str) -> Dict[str, str]:
    """
    Generate a thoughtful journaling prompt using Claude based on the entry content.
    
    Args:
        title: brief string with title of entry.
        body: full body of journal entry.
    
    Returns:
        Dictionary with 'prompt' containing a thoughtful journaling question.
    """
    logger.info(f"[coach_prompt] Starting coach prompt generation for title: {title[:50]}...")
    
    prompt = f"""You are a thoughtful journaling coach helping someone reflect more deeply on their writing.

Title: {title}

Current Entry:
{body}

Based on what they've written so far, generate a single, thoughtful journaling prompt that will help them:
- Explore their feelings more deeply
- Gain new perspectives
- Reflect on what they might be avoiding
- Connect with their authentic self
- Continue their reflection in a meaningful way

The prompt should be:
- A single, open-ended question (1-2 sentences max)
- Thoughtful and encouraging, not judgmental
- Relevant to the content they've written
- Designed to inspire deeper reflection

Examples of good prompts:
- "What's the real feeling underneath this?"
- "What would you tell a friend in this situation?"
- "What's something you're avoiding acknowledging?"
- "What would 'future you' want you to remember today?"
- "What are five things you're grateful for right now?"

Return JSON only: {{"prompt": "..."}}"""

    try:
        logger.info(f"[coach_prompt] Calling Claude API with model: {MODEL}")
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
        logger.info(f"[coach_prompt] Claude API call successful. Stop reason: {message.stop_reason}")
        logger.debug(f"[coach_prompt] Full message object: {message}")
        
        # Extract text from response
        logger.debug(f"[coach_prompt] Message content: {message.content}")
        response_text = message.content[0].text.strip()
        logger.info(f"[coach_prompt] Raw response text: {response_text}")
        
        # Try to parse JSON from the response
        # Claude might wrap JSON in markdown code blocks
        if "```json" in response_text:
            logger.debug("[coach_prompt] Stripping ```json markdown wrapper")
            response_text = response_text.split("```json")[1].split("```")[0].strip()
        elif "```" in response_text:
            logger.debug("[coach_prompt] Stripping ``` markdown wrapper")
            response_text = response_text.split("```")[1].split("```")[0].strip()
        
        logger.debug(f"[coach_prompt] Cleaned response text for JSON parsing: {response_text}")
        result = json.loads(response_text)
        logger.info(f"[coach_prompt] Parsed JSON result: {result}")
        
        # Validate structure
        if 'prompt' not in result:
            logger.error(f"[coach_prompt] Missing 'prompt' field in result: {result}")
            raise ValueError("Missing 'prompt' field in Claude response")
        
        logger.info(f"[coach_prompt] Final prompt: {result['prompt']}")
        
        return result
        
    except json.JSONDecodeError as e:
        logger.error(f"[coach_prompt] JSON decode error: {e}. Response was: {response_text}")
        raise ValueError(f"Failed to parse JSON from Claude response: {e}")
    except Exception as e:
        logger.exception(f"[coach_prompt] Unexpected error during Claude API call: {e}")
        raise RuntimeError(f"Claude API error: {e}")

