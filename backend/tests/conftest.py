import pytest
import os
from unittest.mock import Mock, patch, MagicMock
from fastapi.testclient import TestClient

# Set test environment variables before importing app
os.environ["DB_HOST"] = "localhost"
os.environ["DB_PORT"] = "5432"
os.environ["DB_NAME"] = "test_candid"
os.environ["DB_USER"] = "postgres"
os.environ["DB_PASSWORD"] = "test"
os.environ["ANTHROPIC_API_KEY"] = "test-api-key"
os.environ["TAVILY_API_KEY"] = "test-tavily-key"


@pytest.fixture
def mock_db():
    """Mock database driver for testing."""
    with patch('db.DataBaseDriver') as mock:
        db_instance = MagicMock()
        mock.return_value = db_instance
        yield db_instance


@pytest.fixture
def mock_claude():
    """Mock Claude API client for testing."""
    with patch('services.classification.client') as mock_classification, \
         patch('services.factcheck.claude_client') as mock_factcheck:
        yield {
            'classification': mock_classification,
            'factcheck': mock_factcheck
        }


@pytest.fixture
def mock_tavily():
    """Mock Tavily API client for testing."""
    with patch('services.factcheck.tavily_client') as mock:
        yield mock


@pytest.fixture
def sample_entry():
    """Sample journal entry data."""
    return {
        "title": "My First Day at Work",
        "body": "Today was my first day at the new job. I met my team and learned about the projects we're working on. Everyone was very welcoming."
    }


@pytest.fixture
def sample_entry_response():
    """Sample journal entry response from database."""
    return {
        "id": 1,
        "title": "My First Day at Work",
        "body": "Today was my first day at the new job. I met my team and learned about the projects we're working on. Everyone was very welcoming.",
        "timestamp": "2024-01-15T10:30:00",
        "categories": ["work"]
    }


@pytest.fixture
def sample_category_response():
    """Sample classification response from Claude."""
    return {"category": "work"}


@pytest.fixture
def sample_evidence():
    """Sample evidence record."""
    return {
        "id": 1,
        "entry_id": 1,
        "claim_text": "The Earth orbits the Sun",
        "source_title": "NASA - Solar System",
        "source_url": "https://nasa.gov/solar-system"
    }


@pytest.fixture
def sample_tavily_results():
    """Sample Tavily search results."""
    return {
        "results": [
            {
                "title": "Earth's Orbit - NASA",
                "url": "https://nasa.gov/earth-orbit",
                "content": "Earth orbits the Sun at an average distance of about 93 million miles...",
                "score": 0.92
            },
            {
                "title": "Solar System Facts - Space.com",
                "url": "https://space.com/solar-system",
                "content": "The Earth completes one orbit around the Sun every 365.25 days...",
                "score": 0.85
            },
            {
                "title": "Astronomy Basics - Encyclopedia Britannica",
                "url": "https://britannica.com/astronomy",
                "content": "The heliocentric model places the Sun at the center of the solar system...",
                "score": 0.78
            }
        ]
    }


@pytest.fixture
def sample_factcheck_verdict():
    """Sample fact-check verdict."""
    return {
        "validity_score": 5,
        "reasoning": "The claim is fully supported by multiple high-quality sources including NASA and other reputable astronomy resources.",
        "sources": [
            {"source_title": "Earth's Orbit - NASA", "source_url": "https://nasa.gov/earth-orbit"},
            {"source_title": "Solar System Facts - Space.com", "source_url": "https://space.com/solar-system"}
        ],
        "source_count": 3
    }

