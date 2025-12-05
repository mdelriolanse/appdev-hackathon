# Running Candid on Your Laptop

## Quick Setup (Recommended)

1. **Open Xcode** (if you don't have it, download from Mac App Store)

2. **Create New Project:**
   - File → New → Project
   - Choose "iOS" → "App"
   - Product Name: `Candid`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Click "Next" and save to your project folder

3. **Replace Generated Files:**
   - Delete the auto-generated `ContentView.swift`
   - Copy all Swift files from `frontend/` folder into your Xcode project
   - Make sure `CandidApp.swift` is set as the main entry point

4. **Configure Info.plist:**
   - Update `Info.plist` with the one from `frontend/Info.plist`
   - Or manually add scene configuration if needed

5. **Add Assets:**
   - Copy `Assets.xcassets` folder into your Xcode project

6. **Run:**
   - Select an iOS Simulator (iPhone 15 Pro recommended)
   - Press `Cmd + R` or click the Play button
   - The app will launch in the simulator

## Alternative: Command Line Setup

If you prefer command line, you can create the project structure manually, but Xcode GUI is easier for iOS projects.

## Notes

- Make sure your backend is running on `http://localhost:5000` for API calls to work
- The app stores data locally, so no backend needed for basic journaling
- If API calls fail, the app will still work for creating/viewing entries

