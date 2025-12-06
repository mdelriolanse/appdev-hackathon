from fastapi import APIRouter, HTTPException
from services.coach import coach_prompt
from models import CoachRequest, CoachResponse

router = APIRouter(prefix="/coach", tags=["coach"])


@router.post("", response_model=CoachResponse)
async def get_coach_prompt(request: CoachRequest):
    """Generate a thoughtful journaling prompt based on the entry content."""
    title = request.title
    body = request.body

    if not title or not body:
        raise HTTPException(status_code=400, detail="Title and body are required")

    try:
        result = await coach_prompt(title, body)

        if not result or 'prompt' not in result:
            raise HTTPException(status_code=400, detail="Failed to generate coach prompt")

        return CoachResponse(prompt=result['prompt'])
    
    except ValueError as e:
        raise HTTPException(status_code=502, detail=f"Coach prompt generation failed: {str(e)}")
    except RuntimeError as e:
        raise HTTPException(status_code=502, detail=f"Coach service error: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error: {str(e)}")

