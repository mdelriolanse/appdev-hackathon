import os
import json
import re
import logging
from typing import List, Dict, Optional
from anthropic import Anthropic
from tavily import TavilyClient
from dotenv import load_dotenv
from pydantic import BaseModel, Field

logger = logging.getLogger(__name__)

load_dotenv()

# Initialize API clients
ANTHROPIC_API_KEY = os.getenv("ANTHROPIC_API_KEY")
TAVILY_API_KEY = os.getenv("TAVILY_API_KEY")

if not ANTHROPIC_API_KEY:
    raise ValueError("ANTHROPIC_API_KEY environment variable is required")
if not TAVILY_API_KEY:
    raise ValueError("TAVILY_API_KEY environment variable is required")

claude_client = Anthropic(api_key=ANTHROPIC_API_KEY)
tavily_client = TavilyClient(api_key=TAVILY_API_KEY)

# Use Claude Haiku for fast, cost-effective fact-checking
CLAUDE_MODEL = "claude-3-haiku-20240307"


class FactCheckVerdict(BaseModel):
    """Pydantic model for fact-checking verdict."""
    validity_score: int = Field(..., ge=1, le=5, description="Validity score from 1-5 stars")
    reasoning: str = Field(..., description="Explanation for the validity score")
    sources: List[Dict] = Field(..., description="List of sources with title and URL")
    source_count: int = Field(..., description="Number of sources found")


def extract_core_claim(claim_text: str) -> str:
    """
    STEP 1: Extract the core verifiable claim from highlighted text.
    
    Uses Claude to strip away rhetoric and focus on factual claims that can be researched.
    
    Args:
        claim_text: The highlighted text to fact-check
    
    Returns:
        Extracted claim in 2 sentences or less
    """
    logger.info(f"extract_core_claim called with: '{claim_text}'")
    
    prompt = f"""Extract the core verifiable claim from this text. Focus on factual statements that can be researched and verified, not opinions or rhetoric.

Text: {claim_text}

CRITICAL: You must extract a claim that is DIRECTLY based on the text provided above. Do NOT invent or hallucinate claims that are not present in the input. If the input is nonsensical, random text, or contains no meaningful content, return "NO VERIFIABLE FACTUAL CLAIMS".

Return ONLY the core factual claim in 2 sentences or less. Remove all opinion, rhetoric, and emotional language. Focus on what can be factually verified.

If the text contains no verifiable factual claims (only opinions, insults, emotional statements, or nonsensical text), return "NO VERIFIABLE FACTUAL CLAIMS"."""

    try:
        message = claude_client.messages.create(
            model=CLAUDE_MODEL,
            max_tokens=200,
            messages=[
                {
                    "role": "user",
                    "content": prompt
                }
            ]
        )
        
        claim = message.content[0].text.strip()
        logger.info(f"Extracted claim: '{claim}'")
        return claim
        
    except Exception as e:
        raise RuntimeError(f"Failed to extract core claim: {str(e)}")


def search_for_evidence(claim: str) -> List[Dict]:
    """
    STEP 2: Search for evidence using Tavily API.
    
    Args:
        claim: The extracted core claim to search for
    
    Returns:
        List of search results from Tavily
    """
    try:
        response = tavily_client.search(
            query=claim,
            max_results=10,
            search_depth="advanced"
        )
        
        # Tavily returns results directly or in a 'results' key
        if isinstance(response, dict):
            results = response.get('results', [])
        elif isinstance(response, list):
            results = response
        else:
            results = []
        
        logger.info(f"Search returned {len(results)} results")
        if results:
            logger.info(f"First result title: '{results[0].get('title', 'N/A')}'")
        
        return results
        
    except Exception as e:
        raise RuntimeError(f"Failed to search for evidence: {str(e)}")


def format_tavily_results(results: List[Dict]) -> str:
    """
    Format Tavily search results for Claude analysis.
    
    Args:
        results: List of Tavily search result dictionaries
    
    Returns:
        Formatted string with results
    """
    if not results:
        return "No sources found."
    
    formatted = []
    for i, result in enumerate(results, 1):
        title = result.get('title', 'No title')
        url = result.get('url', 'No URL')
        score = result.get('score', 0)
        content = result.get('content', 'No content')[:500]  # Limit content length
        
        formatted.append(f"""
Source {i}:
Title: {title}
URL: {url}
Relevance Score: {score:.3f}
Content: {content}...
""")
    
    return "\n".join(formatted)


def analyze_and_score(original_claim: str, tavily_results: List[Dict]) -> FactCheckVerdict:
    """
    STEP 3: Analyze evidence and assign validity score.
    
    Uses Claude to analyze the quality and quantity of evidence and assign a 1-5 star score.
    
    Args:
        original_claim: The extracted core claim
        tavily_results: List of Tavily search results
    
    Returns:
        FactCheckVerdict with score, reasoning, and sources
    """
    formatted_results = format_tavily_results(tavily_results)
    source_count = len(tavily_results)
    
    # Calculate average relevance score
    avg_score = 0.0
    if tavily_results:
        scores = [r.get('score', 0) for r in tavily_results]
        avg_score = sum(scores) / len(scores) if scores else 0.0
    
    prompt = f"""You are fact-checking the following claim:

CLAIM TO VERIFY:
{original_claim}

SEARCH RESULTS (filtered for high-quality sources):
{formatted_results}

Assign a validity score from 1-5 stars based on these criteria:

- 5 stars: Fully supported by multiple high-quality sources (average relevance score > 0.8, at least 2-3 sources)
- 4 stars: Mostly supported with good sources (average relevance score > 0.6, at least 2 sources)
- 3 stars: Partially supported, mixed evidence (1-2 sources with moderate scores)
- 2 stars: Limited support from few sources (only 1 source or low average score)
- 1 star: No credible evidence, contradicted by sources, or claim cannot be verified

Average relevance score of sources: {avg_score:.3f}
Number of sources found: {source_count}

Return a JSON object with this exact structure:
{{
    "validity_score": <1-5>,
    "reasoning": "<2-3 sentences explaining the score>"
}}

IMPORTANT: Return ONLY valid JSON, no markdown formatting or extra text."""

    try:
        message = claude_client.messages.create(
            model=CLAUDE_MODEL,
            max_tokens=500,
            messages=[
                {
                    "role": "user",
                    "content": prompt
                }
            ]
        )
        
        response_text = message.content[0].text.strip()
        
        # Extract JSON from response
        if "```json" in response_text:
            response_text = response_text.split("```json")[1].split("```")[0].strip()
        elif "```" in response_text:
            response_text = response_text.split("```")[1].split("```")[0].strip()
        
        # Try to parse JSON
        try:
            result = json.loads(response_text)
        except json.JSONDecodeError:
            # Fallback: extract fields with regex
            validity_match = re.search(r'"validity_score"\s*:\s*(\d+)', response_text)
            validity_score = int(validity_match.group(1)) if validity_match else 3
            
            reasoning_match = re.search(r'"reasoning"\s*:\s*"([^"]*)"', response_text)
            reasoning = reasoning_match.group(1) if reasoning_match else "Unable to parse reasoning"
            
            result = {
                'validity_score': validity_score,
                'reasoning': reasoning
            }
        
        # Validate score
        validity_score = int(result.get('validity_score', 3))
        if validity_score < 1 or validity_score > 5:
            validity_score = 3
        
        # Build sources list
        sources = []
        for r in tavily_results[:3]:
            sources.append({
                'source_title': r.get('title', 'Unknown'),
                'source_url': r.get('url', '')
            })
        
        return FactCheckVerdict(
            validity_score=validity_score,
            reasoning=result.get('reasoning', 'No reasoning provided'),
            sources=sources,
            source_count=source_count
        )
        
    except Exception as e:
        raise RuntimeError(f"Failed to analyze and score: {str(e)}")


def factcheck_claim(claim_text: str) -> FactCheckVerdict:
    """
    Main pipeline function that chains all 3 steps together.
    
    Args:
        claim_text: The text/claim to fact-check
    
    Returns:
        FactCheckVerdict with fact-checking results
    """
    logger.info(f"factcheck_claim called with: '{claim_text}'")
    
    try:
        # Step 1: Extract core claim
        extracted_claim = extract_core_claim(claim_text)
        
        # If no verifiable claims found, return low score
        if extracted_claim.upper() == "NO VERIFIABLE FACTUAL CLAIMS" or not extracted_claim.strip():
            return FactCheckVerdict(
                validity_score=1,
                reasoning="This text contains no verifiable factual claims. It consists only of opinions, rhetoric, or statements that cannot be fact-checked.",
                sources=[],
                source_count=0
            )
        
        # Step 2: Search for evidence
        all_search_results = search_for_evidence(extracted_claim)
        
        # Filter for high-quality sources only (score > 0.5)
        filtered_results = [
            r for r in all_search_results 
            if r.get('score', 0) > 0.5
        ]
        
        top_sources = filtered_results[:5]
        
        # If no sources pass the threshold, return low validity score
        if not top_sources:
            return FactCheckVerdict(
                validity_score=1,
                reasoning="No high-quality sources found. The claim cannot be verified with credible evidence.",
                sources=[],
                source_count=len(all_search_results)
            )
        
        # Step 3: Analyze and score
        verdict = analyze_and_score(extracted_claim, top_sources)
        
        return verdict
        
    except Exception as e:
        # Return a default verdict on error
        return FactCheckVerdict(
            validity_score=1,
            reasoning=f"Fact-checking failed: {str(e)}",
            sources=[],
            source_count=0
        )
