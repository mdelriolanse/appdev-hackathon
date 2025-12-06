# Candid

<img src="frontend/Assets%202.xcassets/AppIcon.appiconset/AppIcon.png" alt="App Icon" width="100" height="100">

A minimalist journaling application with AI-powered features for deeper reflection and self-discovery.

## Overview

Candid is a journaling app that combines the simplicity of traditional journaling with modern AI capabilities. The app helps users explore their thoughts more deeply through intelligent categorization and contextual prompts.

## Features

- **Journal Entry Management**: Create, view, and search through journal entries
- **Auto-Classification**: Entries are automatically categorized using AI based on their content
- **Journaling Coach**: Get contextual prompts while writing to inspire deeper reflection
- **Category Visualization**: View entries organized by categories in an intuitive grid layout
- **Offline Support**: Local caching enables access to entries without an internet connection
- **Entry Templates**: Pre-filled templates for recipes and self-reflection entries
- **Daily Quotes**: Inspirational quotes to start your journaling session

## Technology Stack

### Backend
- FastAPI (Python web framework)
- PostgreSQL (database)
- Anthropic Claude API (classification and coaching)
- psycopg2 (database driver)
- pytest (testing framework)

### iOS Application
- SwiftUI (UI framework)
- Combine (reactive programming)
- UserDefaults (local storage)
- URLSession (HTTP client)

## Project Structure

```
hackathon/
├── backend/              # FastAPI backend server
│   ├── routes/          # API route handlers
│   ├── services/        # Business logic and AI integration
│   ├── models.py        # Pydantic data models
│   ├── db.py            # Database connection and operations
│   └── main.py          # Application entry point
├── Candid/              # iOS SwiftUI application
│   ├── Views/          # SwiftUI view components
│   ├── ViewModels/     # MVVM view models
│   ├── APIService.swift # Network layer
│   └── DesignSystem.swift # UI design system
└── frontend/            # Legacy/unused Swift Package Manager implementation
```

## Setup Instructions

### Backend Setup

1. Install Python dependencies:
```bash
pip install fastapi uvicorn psycopg2-binary anthropic python-dotenv pydantic
```

2. Set up PostgreSQL database and configure environment variables:
```bash
DB_HOST=localhost
DB_PORT=5432
DB_NAME=postgres
DB_USER=postgres
DB_PASSWORD=your_password
ANTHROPIC_API_KEY=your_anthropic_api_key
```

3. Run the backend server:
```bash
cd backend
python main.py
```

The server will start on `http://localhost:8000`

### iOS Setup

1. Open `Candid/Candid.xcodeproj` in Xcode
2. Ensure the backend server is running
3. Build and run the app on a simulator or device

## API Endpoints

- `POST /journal/entry` - Create a new journal entry (auto-classified)
- `GET /journal/entries` - Get all journal entries
- `GET /journal/entry/{id}` - Get a single entry by ID
- `GET /journal/categories` - Get all categories
- `POST /coach` - Get a journaling coach prompt based on entry content

## Database Schema

- **entries**: id, title, body, timestamp
- **categories**: id, name (unique)
- **entry_categories**: entry_id, category_id (many-to-many relationship)
- **evidence**: id, entry_id, claim_text, source_title, source_url

## Development Notes

The fact-checking functionality referenced in some parts of the codebase was not fully implemented. The backend includes fact-check routes and services, but the feature is not active in the current version of the application.

## License

This project was created for the AppDev Hack Challenge.

