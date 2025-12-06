import os
import json
from typing import Dict
from anthropic import AsyncAnthropic
from dotenv import load_dotenv

load_dotenv()

ANTHROPIC_API_KEY = os.getenv("ANTHROPIC_API_KEY")
if not ANTHROPIC_API_KEY:
    raise ValueError("ANTHROPIC_API_KEY environment variable is required")

client = AsyncAnthropic(api_key=ANTHROPIC_API_KEY)
MODEL = "claude-sonnet-4-20250514"


async def coach_prompt(title: str, body: str) -> Dict[str, str]:
    """
    Generate a thoughtful journaling prompt using Claude based on the entry content.
    
    Args:
        title: brief string with title of entry.
        body: full body of journal entry.
    
    Returns:
        Dictionary with 'prompt' containing a thoughtful journaling question.
    """
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
        
        if 'prompt' not in result:
            raise ValueError("Missing 'prompt' field in Claude response")
        
        return result
        
    except json.JSONDecodeError as e:
        raise ValueError(f"Failed to parse JSON from Claude response: {e}")
    except Exception as e:
        raise RuntimeError(f"Claude API error: {e}")

