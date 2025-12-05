# 🚀 Quick Start - Run Candid on Your Mac

## Step-by-Step Instructions

### 1. Open Xcode
```bash
open -a Xcode
```

### 2. Create New Project
- **File** → **New** → **Project** (or `Cmd + Shift + N`)
- Select **iOS** tab → **App**
- Click **Next**

### 3. Configure Project
- **Product Name:** `Candid`
- **Team:** (Select your team or leave default)
- **Organization Identifier:** `com.yourname` (or any identifier)
- **Interface:** **SwiftUI** ⚠️ (IMPORTANT!)
- **Language:** **Swift**
- **Storage:** None (we use UserDefaults)
- Click **Next**
- **Save location:** Choose your project folder or create a new one
- Click **Create**

### 4. Add Your Swift Files
In Xcode:
1. **Delete** the auto-generated `ContentView.swift` file
2. **Right-click** on your project folder in the left sidebar
3. **Add Files to "Candid"...**
4. Navigate to `frontend/` folder
5. Select ALL these Swift files:
   - `CandidApp.swift` ⭐ (Main entry point)
   - `MainTabView.swift`
   - `EntryListView.swift`
   - `EntryDetailView.swift`
   - `NewEntryView.swift`
   - `CategoryBlocksView.swift`
   - `EntryListViewModel.swift`
   - `EntryDetailViewModel.swift`
   - `NewEntryViewModel.swift`
   - `JournalEntry.swift`
   - `PersistenceManager.swift`
   - `APIService.swift`
   - `DesignSystem.swift`
   - `DailyQuote.swift`
6. Make sure **"Copy items if needed"** is checked
7. Click **Add**

### 5. Add Assets
1. Right-click project → **Add Files to "Candid"...**
2. Select `frontend/Assets.xcassets` folder
3. Click **Add**

### 6. Update Info.plist (Optional)
- Your project already has an Info.plist
- The one in `frontend/Info.plist` is updated for SwiftUI
- You can copy its contents if needed

### 7. Set Main Entry Point
- Make sure `CandidApp.swift` is in your project
- Xcode should automatically detect `@main` attribute

### 8. Run the App! 🎉
1. Select a simulator: **iPhone 15 Pro** (or any iOS 16+ device)
2. Press **`Cmd + R`** or click the **▶️ Play** button
3. The app will launch in the iOS Simulator

## Troubleshooting

**"Cannot find type 'CandidColors'"**
- Make sure `DesignSystem.swift` is added to the project

**"Cannot find 'PersistenceManager'"**
- Make sure `PersistenceManager.swift` is added

**App crashes on launch**
- Check that `CandidApp.swift` has `@main` attribute
- Make sure all files are added to the target (check in File Inspector)

**API calls not working**
- Start your backend: `cd backend && python app.py`
- Backend should run on `http://localhost:5000`
- App works without backend for basic journaling

## Alternative: Use Xcode Command Line

If you prefer terminal:
```bash
cd /path/to/your/project
xcodebuild -scheme Candid -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build
```

But GUI is much easier! 🎨

