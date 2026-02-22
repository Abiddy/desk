# Xcode Setup Guide - Step by Step

## Step 1: Create New Xcode Project

1. **Open Xcode**
2. **File → New → Project** (or `Cmd + Shift + N`)
3. Select **iOS** tab
4. Choose **App** template
5. Click **Next**

## Step 2: Configure Project Settings

Fill in the project details:

- **Product Name**: `HelpDeskCommunity`
- **Team**: Select your Apple Developer account (or "None" for now)
- **Organization Identifier**: `com.yourcompany` (or your domain)
- **Bundle Identifier**: Will auto-generate as `com.yourcompany.HelpDeskCommunity`
- **Interface**: **SwiftUI** ✅
- **Language**: **Swift** ✅
- **Storage**: **SwiftData** ✅ (important!)
- **Include Tests**: ✅ (optional but recommended)

6. Click **Next**
7. Choose where to save (you can save it in the same folder as our code, or create a new folder)
8. Click **Create**

## Step 3: Add Our Files to Xcode

You have two options:

### Option A: Copy Files Into Xcode Project (Recommended)

1. In Xcode, right-click on the **HelpDeskCommunity** folder (blue icon) in the Project Navigator
2. Select **Add Files to "HelpDeskCommunity"...**
3. Navigate to the folder where our code files are (`/Users/noumanabidi/Desktop/community-app/HelpDeskCommunity/`)
4. Select these folders/files:
   - `App/` folder (contains AppDelegate.swift)
   - `Models/` folder
   - `ViewModels/` folder
   - `Views/` folder
   - `Services/` folder
   - `Utilities/` folder
5. Make sure these options are checked:
   - ✅ **Copy items if needed** (if files are outside project folder)
   - ✅ **Create groups** (not folder references)
   - ✅ **Add to targets: HelpDeskCommunity**
6. Click **Add**

### Option B: Replace Default Files

1. Delete the default `ContentView.swift` that Xcode created
2. Delete the default `HelpDeskCommunityApp.swift` (if it exists)
3. Add our files using Option A above

## Step 4: Update App Entry Point

1. Open `HelpDeskCommunityApp.swift` (our version)
2. Make sure it has the `@main` attribute and `@UIApplicationDelegateAdaptor`
3. If Xcode created a different entry point, delete it and use ours

## Step 5: Add Firebase SDK

### Using Swift Package Manager (Recommended)

1. In Xcode: **File → Add Package Dependencies...**
2. Enter this URL: `https://github.com/firebase/firebase-ios-sdk`
3. Click **Add Package**
4. Select version: **Up to Next Major Version** with `10.0.0`
5. Click **Add Package**
6. Select these products (check the boxes):
   - ✅ FirebaseAuth
   - ✅ FirebaseFirestore
   - ✅ FirebaseStorage
   - ✅ FirebaseMessaging
   - ✅ FirebaseFunctions
   - ✅ FirebaseCore (usually auto-selected)
7. Click **Add Package**

## Step 6: Add Firebase Configuration File

1. Download `GoogleService-Info.plist` from Firebase Console (see `FirebaseSetup.md`)
2. In Xcode, right-click on the **HelpDeskCommunity** folder (top level, blue icon)
3. Select **Add Files to "HelpDeskCommunity"...**
4. Select `GoogleService-Info.plist`
5. Make sure:
   - ✅ **Copy items if needed** is checked
   - ✅ **Add to targets: HelpDeskCommunity** is checked
6. Click **Add**

## Step 7: Update Info.plist

1. In Xcode, find `Info.plist` in Project Navigator
2. Right-click → **Open As → Source Code**
3. Add these keys before `</dict>`:

```xml
<!-- Location Permission -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to display it on your profile and show relevant local ads.</string>

<!-- Camera Permission -->
<key>NSCameraUsageDescription</key>
<string>We need access to your camera to take profile pictures and share photos in private chats.</string>

<!-- Photo Library Permission -->
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photo library to select profile pictures and share photos in private chats.</string>

<!-- Microphone Permission -->
<key>NSMicrophoneUsageDescription</key>
<string>We need access to your microphone for voice calls and audio messages.</string>
```

Or use the **Info** tab in Target Settings:
1. Select **HelpDeskCommunity** project (blue icon)
2. Select **HelpDeskCommunity** target
3. Go to **Info** tab
4. Click **+** to add new keys
5. Add each permission key and description

## Step 8: Configure Build Settings

1. Select **HelpDeskCommunity** project (blue icon)
2. Select **HelpDeskCommunity** target
3. Go to **Build Settings** tab
4. Search for "Swift Language Version"
5. Set to **Swift 5** or latest
6. Search for "iOS Deployment Target"
7. Set to **iOS 17.0** (or minimum iOS 15.0)

## Step 9: Fix Import Statements

Make sure all files have proper imports:

- Files using Firebase need: `import FirebaseAuth`, `import FirebaseFirestore`, etc.
- Files using SwiftUI need: `import SwiftUI`
- Files using SwiftData need: `import SwiftData`
- Files using CoreLocation need: `import CoreLocation`

## Step 10: Build and Fix Errors

1. Press **Cmd + B** to build
2. Fix any import errors or missing dependencies
3. Common fixes:
   - Add missing imports
   - Check that all files are added to the target
   - Verify Firebase SDK is properly installed

## Step 11: Run the App

1. Select a simulator (e.g., iPhone 15 Pro) from the device selector
2. Press **Cmd + R** to run
3. The app should launch!

## Project Structure in Xcode Should Look Like:

```
HelpDeskCommunity (blue folder icon)
├── App
│   ├── AppDelegate.swift
│   └── HelpDeskCommunityApp.swift
├── Models
│   ├── User.swift
│   ├── Group.swift
│   └── Message.swift
├── ViewModels
│   └── AuthViewModel.swift
├── Views
│   ├── ContentView.swift
│   ├── Authentication/
│   │   ├── AuthenticationView.swift
│   │   ├── NDAView.swift
│   │   └── EmailVerificationView.swift
│   └── MainTabView.swift
├── Services
│   ├── AuthService.swift
│   └── LocationService.swift
├── Utilities
│   ├── Constants.swift
│   └── Extensions/
│       └── String+Extensions.swift
├── Assets.xcassets
├── Info.plist
└── GoogleService-Info.plist
```

## Troubleshooting

### "No such module 'FirebaseAuth'"
- Make sure Firebase SDK is added via Swift Package Manager
- Clean build folder: **Product → Clean Build Folder** (`Cmd + Shift + K`)
- Rebuild: **Product → Build** (`Cmd + B`)

### "Cannot find 'User' in scope"
- Make sure all Swift files are added to the target
- Check that `import SwiftData` is present
- Verify SwiftData models are properly defined

### "Missing GoogleService-Info.plist"
- Download from Firebase Console
- Add to project root (same level as Info.plist)
- Make sure it's added to the target

### Build Errors
- Check iOS Deployment Target matches SwiftData requirements (iOS 17+)
- Verify all imports are correct
- Clean and rebuild

## Next Steps After Setup

1. ✅ Project builds successfully
2. ✅ App runs on simulator
3. ✅ Follow `FirebaseSetup.md` to configure Firebase
4. ✅ Test authentication flow
5. ✅ Ready for Phase 2 development!

## Quick Checklist

- [ ] Xcode project created
- [ ] All files added to project
- [ ] Firebase SDK installed
- [ ] GoogleService-Info.plist added
- [ ] Info.plist permissions added
- [ ] Project builds without errors
- [ ] App runs on simulator
- [ ] Firebase configured (see FirebaseSetup.md)
