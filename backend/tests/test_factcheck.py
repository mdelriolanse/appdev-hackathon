import pytest
from unittest.mock import patch, MagicMock
from fastapi.testclient import TestClient


class TestFactCheckEndpoint:
    """Tests for POST /factcheck endpoint."""

    def test_factcheck_success(self, sample_entry_response, sample_evidence, sample_tavily_results):
        """Test successful fact-check of a claim."""
        with patch('db.DataBaseDriver') as mock_db_class, \
             patch('services.factcheck.claude_client') as mock_claude, \
             patch('services.factcheck.tavily_client') as mock_tavily, \
             patch('services.classification.DB'):
            
            # Setup mocks
            mock_db = MagicMock()
            mock_db_class.return_value = mock_db
            mock_db.get_entry_by_id.return_value = sample_entry_response
            mock_db.create_evidence.return_value = sample_evidence
            
            # Mock Claude responses
            mock_extract_response = MagicMock()
            mock_extract_response.content = [MagicMock(text="The Earth orbits the Sun.")]
            
            mock_analyze_response = MagicMock()
            mock_analyze_response.content = [MagicMock(text='{"validity_score": 5, "reasoning": "Fully supported by multiple sources."}')]
            
            mock_claude.messages.create.side_effect = [mock_extract_response, mock_analyze_response]
            
            # Mock Tavily search
            mock_tavily.search.return_value = sample_tavily_results
            
            from main import app
            client = TestClient(app)
            
            response = client.post("/factcheck", json={
                "entry_id": 1,
                "claim_text": "The Earth orbits the Sun"
            })
            
            assert response.status_code == 200
            data = response.json()
            assert "validity_score" in data
            assert "reasoning" in data
            assert "evidence" in data
            assert data["claim_text"] == "The Earth orbits the Sun"

    def test_factcheck_entry_not_found(self):
        """Test fact-check fails when entry doesn't exist."""
        from exceptions import EntryNotFoundError
        
        with patch('routes.factcheck.DB') as mock_db, \
             patch('routes.journal_entry.DB'), \
             patch('services.classification.DB'):
            
            mock_db.get_entry_by_id.side_effect = EntryNotFoundError("Entry not found")
            
            from main import app
            client = TestClient(app)
            
            response = client.post("/factcheck", json={
                "entry_id": 999,
                "claim_text": "Some claim"
            })
            
            assert response.status_code == 404

    def test_factcheck_empty_claim(self, sample_entry_response):
        """Test fact-check fails with empty claim text."""
        with patch('db.DataBaseDriver') as mock_db_class, \
             patch('services.classification.DB'):
            
            mock_db = MagicMock()
            mock_db_class.return_value = mock_db
            mock_db.get_entry_by_id.return_value = sample_entry_response
            
            from main import app
            client = TestClient(app)
            
            response = client.post("/factcheck", json={
                "entry_id": 1,
                "claim_text": ""
            })
            
            assert response.status_code == 400

    def test_factcheck_whitespace_claim(self, sample_entry_response):
        """Test fact-check fails with whitespace-only claim."""
        with patch('db.DataBaseDriver') as mock_db_class, \
             patch('services.classification.DB'):
            
            mock_db = MagicMock()
            mock_db_class.return_value = mock_db
            mock_db.get_entry_by_id.return_value = sample_entry_response
            
            from main import app
            client = TestClient(app)
            
            response = client.post("/factcheck", json={
                "entry_id": 1,
                "claim_text": "   "
            })
            
            assert response.status_code == 400

    def test_factcheck_missing_entry_id(self):
        """Test fact-check fails without entry_id."""
        with patch('db.DataBaseDriver') as mock_db_class, \
             patch('services.classification.DB'):
            
            mock_db = MagicMock()
            mock_db_class.return_value = mock_db
            
            from main import app
            client = TestClient(app)
            
            response = client.post("/factcheck", json={
                "claim_text": "Some claim"
            })
            
            assert response.status_code == 422  # Validation error

    def test_factcheck_no_verifiable_claims(self, sample_entry_response):
        """Test fact-check handles non-verifiable claims."""
        with patch('db.DataBaseDriver') as mock_db_class, \
             patch('services.factcheck.claude_client') as mock_claude, \
             patch('services.factcheck.tavily_client') as mock_tavily, \
             patch('services.classification.DB'):
            
            mock_db = MagicMock()
            mock_db_class.return_value = mock_db
            mock_db.get_entry_by_id.return_value = sample_entry_response
            
            # Mock Claude to return no verifiable claims
            mock_extract_response = MagicMock()
            mock_extract_response.content = [MagicMock(text="NO VERIFIABLE FACTUAL CLAIMS")]
            mock_claude.messages.create.return_value = mock_extract_response
            
            from main import app
            client = TestClient(app)
            
            response = client.post("/factcheck", json={
                "entry_id": 1,
                "claim_text": "I think pizza is the best food ever!"
            })
            
            assert response.status_code == 200
            data = response.json()
            assert data["validity_score"] == 1
            assert "no verifiable" in data["reasoning"].lower()

    def test_factcheck_no_sources_found(self, sample_entry_response):
        """Test fact-check handles when no sources are found."""
        with patch('db.DataBaseDriver') as mock_db_class, \
             patch('services.factcheck.claude_client') as mock_claude, \
             patch('services.factcheck.tavily_client') as mock_tavily, \
             patch('services.classification.DB'):
            
            mock_db = MagicMock()
            mock_db_class.return_value = mock_db
            mock_db.get_entry_by_id.return_value = sample_entry_response
            
            # Mock Claude extract
            mock_extract_response = MagicMock()
            mock_extract_response.content = [MagicMock(text="Some verifiable claim.")]
            mock_claude.messages.create.return_value = mock_extract_response
            
            # Mock Tavily to return no results or low-score results
            mock_tavily.search.return_value = {"results": [
                {"title": "Low quality", "url": "http://example.com", "score": 0.2, "content": "..."}
            ]}
            
            from main import app
            client = TestClient(app)
            
            response = client.post("/factcheck", json={
                "entry_id": 1,
                "claim_text": "Some obscure claim"
            })
            
            assert response.status_code == 200
            data = response.json()
            assert data["validity_score"] == 1


class TestFactCheckService:
    """Tests for the factcheck service functions."""

    def test_extract_core_claim(self):
        """Test core claim extraction."""
        with patch('services.factcheck.claude_client') as mock_claude:
            mock_response = MagicMock()
            mock_response.content = [MagicMock(text="The Earth is approximately 4.5 billion years old.")]
            mock_claude.messages.create.return_value = mock_response
            
            from services.factcheck import extract_core_claim
            
            result = extract_core_claim("Scientists say the Earth is about 4.5 billion years old, which is amazing!")
            
            assert "4.5 billion" in result
            mock_claude.messages.create.assert_called_once()

    def test_search_for_evidence(self, sample_tavily_results):
        """Test evidence search via Tavily."""
        with patch('services.factcheck.tavily_client') as mock_tavily:
            mock_tavily.search.return_value = sample_tavily_results
            
            from services.factcheck import search_for_evidence
            
            results = search_for_evidence("The Earth orbits the Sun")
            
            assert len(results) == 3
            assert results[0]["title"] == "Earth's Orbit - NASA"
            mock_tavily.search.assert_called_once()

    def test_format_tavily_results(self, sample_tavily_results):
        """Test formatting of Tavily results."""
        from services.factcheck import format_tavily_results
        
        formatted = format_tavily_results(sample_tavily_results["results"])
        
        assert "Source 1:" in formatted
        assert "NASA" in formatted
        assert "Relevance Score:" in formatted

    def test_format_tavily_results_empty(self):
        """Test formatting with empty results."""
        from services.factcheck import format_tavily_results
        
        formatted = format_tavily_results([])
        
        assert formatted == "No sources found."

