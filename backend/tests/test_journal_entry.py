import pytest
from unittest.mock import patch, MagicMock, AsyncMock
from fastapi.testclient import TestClient
from fastapi import FastAPI
from datetime import datetime


class TestCreateJournalEntry:
    """Tests for POST /journal/entry endpoint."""

    def test_create_entry_success(self, sample_entry, sample_entry_response, sample_category_response):
        """Test successful journal entry creation."""
        with patch('db.DataBaseDriver') as mock_db_class, \
             patch('services.classification.classify_entry', new_callable=AsyncMock) as mock_classify, \
             patch('services.classification.DB'):
            
            # Setup mocks
            mock_db = MagicMock()
            mock_db_class.return_value = mock_db
            mock_db.create_entry.return_value = sample_entry_response
            mock_classify.return_value = sample_category_response
            
            # Import after patching
            from main import app
            client = TestClient(app)
            
            response = client.post("/journal/entry", json=sample_entry)
            
            assert response.status_code == 200
            data = response.json()
            assert data["title"] == sample_entry["title"]
            assert data["body"] == sample_entry["body"]
            assert "categories" in data

    def test_create_entry_missing_title(self):
        """Test entry creation fails with missing title."""
        with patch('db.DataBaseDriver') as mock_db_class, \
             patch('services.classification.DB'):
            
            mock_db = MagicMock()
            mock_db_class.return_value = mock_db
            
            from main import app
            client = TestClient(app)
            
            response = client.post("/journal/entry", json={"body": "Some content"})
            
            assert response.status_code == 422  # Validation error

    def test_create_entry_missing_body(self):
        """Test entry creation fails with missing body."""
        with patch('db.DataBaseDriver') as mock_db_class, \
             patch('services.classification.DB'):
            
            mock_db = MagicMock()
            mock_db_class.return_value = mock_db
            
            from main import app
            client = TestClient(app)
            
            response = client.post("/journal/entry", json={"title": "Some title"})
            
            assert response.status_code == 422  # Validation error

    def test_create_entry_empty_title(self, sample_category_response):
        """Test entry creation fails with empty title."""
        with patch('db.DataBaseDriver') as mock_db_class, \
             patch('services.classification.classify_entry', new_callable=AsyncMock) as mock_classify, \
             patch('services.classification.DB'):
            
            mock_db = MagicMock()
            mock_db_class.return_value = mock_db
            mock_classify.return_value = sample_category_response
            
            from main import app
            client = TestClient(app)
            
            response = client.post("/journal/entry", json={"title": "", "body": "Some content"})
            
            assert response.status_code == 400


class TestGetAllJournalEntries:
    """Tests for GET /journal/entries endpoint."""

    def test_get_all_entries_success(self, sample_entry_response):
        """Test successful retrieval of all entries."""
        with patch('db.DataBaseDriver') as mock_db_class, \
             patch('services.classification.DB'):
            
            mock_db = MagicMock()
            mock_db_class.return_value = mock_db
            mock_db.get_all_entries.return_value = [sample_entry_response]
            
            from main import app
            client = TestClient(app)
            
            response = client.get("/journal/entries")
            
            assert response.status_code == 200
            data = response.json()
            assert isinstance(data, list)
            assert len(data) == 1
            assert data[0]["title"] == sample_entry_response["title"]

    def test_get_all_entries_empty(self):
        """Test retrieval when no entries exist."""
        with patch('db.DataBaseDriver') as mock_db_class, \
             patch('services.classification.DB'):
            
            mock_db = MagicMock()
            mock_db_class.return_value = mock_db
            mock_db.get_all_entries.return_value = []
            
            from main import app
            client = TestClient(app)
            
            response = client.get("/journal/entries")
            
            assert response.status_code == 200
            data = response.json()
            assert data == []


class TestGetJournalEntryById:
    """Tests for GET /journal/entry/{id} endpoint."""

    def test_get_entry_by_id_success(self, sample_entry_response):
        """Test successful retrieval of entry by ID."""
        with patch('db.DataBaseDriver') as mock_db_class, \
             patch('services.classification.DB'):
            
            mock_db = MagicMock()
            mock_db_class.return_value = mock_db
            mock_db.get_entry_by_id.return_value = sample_entry_response
            
            from main import app
            client = TestClient(app)
            
            response = client.get("/journal/entry/1")
            
            assert response.status_code == 200
            data = response.json()
            assert data["id"] == 1
            assert data["title"] == sample_entry_response["title"]

    def test_get_entry_by_id_not_found(self):
        """Test retrieval of non-existent entry."""
        with patch('db.DataBaseDriver') as mock_db_class, \
             patch('services.classification.DB'):
            
            from exceptions import EntryNotFoundError
            
            mock_db = MagicMock()
            mock_db_class.return_value = mock_db
            mock_db.get_entry_by_id.side_effect = EntryNotFoundError("Entry not found")
            
            from main import app
            client = TestClient(app)
            
            response = client.get("/journal/entry/999")
            
            assert response.status_code == 404


class TestGetEntryEvidence:
    """Tests for GET /journal/entry/{id}/evidence endpoint."""

    def test_get_entry_evidence_success(self, sample_entry_response, sample_evidence):
        """Test successful retrieval of entry evidence."""
        with patch('db.DataBaseDriver') as mock_db_class, \
             patch('services.classification.DB'):
            
            mock_db = MagicMock()
            mock_db_class.return_value = mock_db
            mock_db.get_entry_by_id.return_value = sample_entry_response
            mock_db.get_evidence_for_entry.return_value = [sample_evidence]
            
            from main import app
            client = TestClient(app)
            
            response = client.get("/journal/entry/1/evidence")
            
            assert response.status_code == 200
            data = response.json()
            assert isinstance(data, list)
            assert len(data) == 1
            assert data[0]["claim_text"] == sample_evidence["claim_text"]

    def test_get_entry_evidence_entry_not_found(self):
        """Test evidence retrieval for non-existent entry."""
        with patch('db.DataBaseDriver') as mock_db_class, \
             patch('services.classification.DB'):
            
            from exceptions import EntryNotFoundError
            
            mock_db = MagicMock()
            mock_db_class.return_value = mock_db
            mock_db.get_entry_by_id.side_effect = EntryNotFoundError("Entry not found")
            
            from main import app
            client = TestClient(app)
            
            response = client.get("/journal/entry/999/evidence")
            
            assert response.status_code == 404

    def test_get_entry_evidence_empty(self, sample_entry_response):
        """Test evidence retrieval when no evidence exists."""
        with patch('db.DataBaseDriver') as mock_db_class, \
             patch('services.classification.DB'):
            
            mock_db = MagicMock()
            mock_db_class.return_value = mock_db
            mock_db.get_entry_by_id.return_value = sample_entry_response
            mock_db.get_evidence_for_entry.return_value = []
            
            from main import app
            client = TestClient(app)
            
            response = client.get("/journal/entry/1/evidence")
            
            assert response.status_code == 200
            data = response.json()
            assert data == []

