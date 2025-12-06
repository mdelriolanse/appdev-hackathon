from fastapi import APIRouter, HTTPException
import logging
from services.coach import coach_prompt
from models import CoachRequest, CoachResponse

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/coach", tags=["coach"])


@router.post("", response_model=CoachResponse)
async def get_coach_prompt(request: CoachRequest):
    """Generate a thoughtful journaling prompt based on the entry content."""
    logger.info(f"[POST /coach] Received request for coach prompt")
    title = request.title
    body = request.body
    logger.debug(f"[POST /coach] Title: {title[:50]}..., Body length: {len(body)}")

    if not title or not body:
        logger.warning("[POST /coach] Missing title or body in request")
        raise HTTPException(status_code=400, detail="Title and body are required")

    try:
        # Generate coach prompt using Claude
        logger.info("[POST /coach] Calling coach_prompt...")
        result = await coach_prompt(title, body)
        logger.info(f"[POST /coach] Coach prompt generated successfully")

        if not result or 'prompt' not in result:
            logger.error(f"[POST /coach] Invalid coach prompt result: {result}")
            raise HTTPException(status_code=400, detail="Failed to generate coach prompt")

        return CoachResponse(prompt=result['prompt'])
    
    except ValueError as e:
        # Claude JSON parsing error
        logger.error(f"[POST /coach] ValueError (JSON parsing): {e}")
        raise HTTPException(status_code=502, detail=f"Coach prompt generation failed: {str(e)}")
    except RuntimeError as e:
        # Claude API error
        logger.error(f"[POST /coach] RuntimeError (Claude API): {e}")
        raise HTTPException(status_code=502, detail=f"Coach service error: {str(e)}")
    except Exception as e:
        # Catch-all for unexpected errors
        logger.exception(f"[POST /coach] Unexpected error: {e}")
        raise HTTPException(status_code=500, detail=f"Unexpected error: {str(e)}")

