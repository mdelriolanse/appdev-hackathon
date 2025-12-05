import pytest
from unittest.mock import patch, MagicMock
from fastapi.testclient import TestClient


class TestGetAllCategories:
    """Tests for GET /journal/categories endpoint."""

    def test_get_categories_success(self):
        """Test successful retrieval of all categories."""
        with patch('db.DataBaseDriver') as mock_db_class, \
             patch('services.classification.DB'):
            
            mock_db = MagicMock()
            mock_db_class.return_value = mock_db
            mock_db.get_all_categories.return_value = [
                {"id": 1, "name": "work"},
                {"id": 2, "name": "personal"},
                {"id": 3, "name": "health"}
            ]
            
            from main import app
            client = TestClient(app)
            
            response = client.get("/journal/categories")
            
            assert response.status_code == 200
            data = response.json()
            assert isinstance(data, list)
            assert len(data) == 3
            assert data[0]["name"] == "work"

    def test_get_categories_empty(self):
        """Test retrieval when no categories exist."""
        with patch('db.DataBaseDriver') as mock_db_class, \
             patch('services.classification.DB'):
            
            mock_db = MagicMock()
            mock_db_class.return_value = mock_db
            mock_db.get_all_categories.return_value = []
            
            from main import app
            client = TestClient(app)
            
            response = client.get("/journal/categories")
            
            assert response.status_code == 200
            data = response.json()
            assert data == []


class TestCategoryClassification:
    """Tests for category classification integration."""

    def test_classification_uses_existing_categories(self):
        """Test that classification service fetches existing categories."""
        with patch('services.classification.client') as mock_claude, \
             patch('services.classification.DB') as mock_db:
            
            # Setup mock database with existing categories
            mock_db.get_all_categories.return_value = [
                {"id": 1, "name": "work"},
                {"id": 2, "name": "personal"},
                {"id": 3, "name": "health"}
            ]
            
            # Setup mock Claude response
            mock_response = MagicMock()
            mock_response.content = [MagicMock(text='{"category": "work"}')]
            mock_claude.messages.create.return_value = mock_response
            
            import asyncio
            from services.classification import classify_entry
            
            result = asyncio.run(classify_entry("Meeting notes", "Discussed Q4 goals with the team"))
            
            # Verify database was queried for categories
            mock_db.get_all_categories.assert_called_once()
            
            # Verify Claude was called
            mock_claude.messages.create.assert_called_once()
            
            # Verify the prompt includes existing categories
            call_args = mock_claude.messages.create.call_args
            prompt = call_args[1]["messages"][0]["content"]
            assert "EXISTING CATEGORIES" in prompt
            assert "work" in prompt

    def test_classification_normalizes_to_lowercase(self):
        """Test that classification normalizes categories to lowercase."""
        with patch('services.classification.client') as mock_claude, \
             patch('services.classification.DB') as mock_db:
            
            mock_db.get_all_categories.return_value = []
            
            mock_response = MagicMock()
            mock_response.content = [MagicMock(text='{"category": "WORK"}')]
            mock_claude.messages.create.return_value = mock_response
            
            import asyncio
            from services.classification import classify_entry
            
            result = asyncio.run(classify_entry("Test", "Test body"))
            
            assert result["category"] == "work"  # Should be lowercase

    def test_classification_handles_no_existing_categories(self):
        """Test classification when database has no categories."""
        with patch('services.classification.client') as mock_claude, \
             patch('services.classification.DB') as mock_db:
            
            mock_db.get_all_categories.return_value = []
            
            mock_response = MagicMock()
            mock_response.content = [MagicMock(text='{"category": "travel"}')]
            mock_claude.messages.create.return_value = mock_response
            
            import asyncio
            from services.classification import classify_entry
            
            result = asyncio.run(classify_entry("Trip to Paris", "Visited the Eiffel Tower"))
            
            # Verify prompt mentions no existing categories
            call_args = mock_claude.messages.create.call_args
            prompt = call_args[1]["messages"][0]["content"]
            assert "No existing categories" in prompt
            
            assert result["category"] == "travel"

