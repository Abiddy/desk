# Help Desk Community iOS App

A community help desk application built with SwiftUI, Firebase, and SwiftData.

## Tech Stack

- **iOS**: SwiftUI + Swift Concurrency (async/await)
- **Local Storage**: SwiftData
- **Backend**: Firebase (Auth + Firestore + Functions + Storage + FCM)
- **Search**: Algolia/Typesense (to be integrated)

## Project Structure

```
HelpDeskCommunity/
├── App/
│   └── HelpDeskCommunityApp.swift       # App entry point
├── Models/
│   ├── User.swift                        # User model (SwiftData)
│   ├── Group.swift                       # Group model (SwiftData)
│   └── Message.swift                     # Message model (SwiftData)
├── ViewModels/
│   └── AuthViewModel.swift               # Authentication view model
├── Views/
│   ├── ContentView.swift                 # Root view
│   ├── Authentication/
│   │   ├── AuthenticationView.swift      # Login/Signup
│   │   ├── NDAView.swift                 # NDA popup
│   │   └── EmailVerificationView.swift   # Email verification
│   └── MainTabView.swift                 # Main app tabs
├── Services/
│   ├── AuthService.swift                 # Firebase Auth service
│   └── LocationService.swift             # Core Location service
└── Utilities/
    ├── Constants.swift                    # App constants
    └── Extensions/
        └── String+Extensions.swift        # String utilities
```

## Phase 1 Features Implemented

✅ **Project Setup**
- SwiftUI project structure
- MVVM architecture
- SwiftData models for local caching

✅ **Authentication**
- Email/password sign up
- Email verification flow
- Sign in with verified email
- User profile creation in Firestore

✅ **NDA Popup**
- Non-disclosure agreement on first launch
- Persistent acceptance via UserDefaults

✅ **Location Services**
- Core Location integration
- Reverse geocoding for location string
- Permission handling

✅ **User Profile**
- Profile view with location display
- Settings navigation structure
- Sign out functionality

## Firebase Setup Required

1. **Create Firebase Project**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create a new project
   - Add iOS app with bundle ID

2. **Download GoogleService-Info.plist**
   - Download the configuration file
   - Add it to the Xcode project root

3. **Enable Authentication**
   - Go to Authentication → Sign-in method
   - Enable Email/Password authentication

4. **Create Firestore Database**
   - Go to Firestore Database
   - Create database in test mode (we'll add security rules later)
   - Create collections: `users`, `groups`, `messages`, `privateChats`

5. **Install Firebase SDK**
   Add to your `Package.swift` or use CocoaPods/SPM:
   ```swift
   dependencies: [
       .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.0.0")
   ]
   ```

## Required Permissions

Add to `Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to display it on your profile and show relevant local ads.</string>
```

## Next Steps (Phase 2)

- [ ] Real-time chat implementation
- [ ] Group creation and joining
- [ ] Message sending and receiving
- [ ] Chat history loading
- [ ] Typing indicators
- [ ] Read receipts
- [ ] Last seen functionality

## Development Notes

- All async operations use Swift Concurrency (async/await)
- SwiftData models sync with Firestore
- Location services require user permission
- Email verification is required before app access
