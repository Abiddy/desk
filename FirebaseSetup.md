# Firebase Setup Guide

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: "HelpDeskCommunity"
4. Follow the setup wizard

## Step 2: Add iOS App

1. In Firebase Console, click the iOS icon
2. Register your app:
   - **Bundle ID**: `com.yourcompany.HelpDeskCommunity` (update in Xcode)
   - **App nickname**: Help Desk Community iOS
   - **App Store ID**: (leave blank for now)
3. Download `GoogleService-Info.plist`
4. Add `GoogleService-Info.plist` to your Xcode project root

## Step 3: Install Firebase SDK

### Using Swift Package Manager (Recommended)

1. In Xcode: File → Add Packages...
2. Enter: `https://github.com/firebase/firebase-ios-sdk`
3. Select version: `10.0.0` or later
4. Add these products:
   - FirebaseAuth
   - FirebaseFirestore
   - FirebaseStorage
   - FirebaseMessaging
   - FirebaseFunctions

### Using CocoaPods (Alternative)

Add to `Podfile`:
```ruby
platform :ios, '15.0'
use_frameworks!

target 'HelpDeskCommunity' do
  pod 'FirebaseAuth'
  pod 'FirebaseFirestore'
  pod 'FirebaseStorage'
  pod 'FirebaseMessaging'
  pod 'FirebaseFunctions'
end
```

Run: `pod install`

## Step 4: Initialize Firebase

Add to `HelpDeskCommunityApp.swift` (before `@main`):

```swift
import FirebaseCore

// In AppDelegate or App init
FirebaseApp.configure()
```

Or create `AppDelegate.swift`:

```swift
import UIKit
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}
```

Then update `HelpDeskCommunityApp.swift`:

```swift
@main
struct HelpDeskCommunityApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    // ... rest of code
}
```

## Step 5: Enable Authentication

1. Go to Firebase Console → Authentication
2. Click "Get started"
3. Go to "Sign-in method" tab
4. Enable "Email/Password"
5. Click "Save"

## Step 6: Create Firestore Database

1. Go to Firebase Console → Firestore Database
2. Click "Create database"
3. Choose "Start in test mode" (we'll add security rules later)
4. Select location (choose closest to your users)
5. Click "Enable"

## Step 7: Firestore Security Rules (Initial)

Go to Firestore → Rules tab:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Groups - anyone authenticated can read, only moderators can write
    match /groups/{groupId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        (request.resource.data.moderators.hasAny([request.auth.uid]) || 
         resource == null);
    }
    
    // Messages - authenticated users can read/write
    match /messages/{messageId} {
      allow read, write: if request.auth != null;
    }
    
    // Private chats - only participants can access
    match /privateChats/{chatId} {
      allow read, write: if request.auth != null && 
        request.auth.uid in resource.data.participants;
    }
  }
}
```

## Step 8: Storage Setup (for Phase 3)

1. Go to Firebase Console → Storage
2. Click "Get started"
3. Start in test mode
4. Choose location (same as Firestore)

## Step 9: Cloud Messaging Setup (for Push Notifications)

1. Go to Firebase Console → Cloud Messaging
2. Upload your APNs certificate or key:
   - For development: Use APNs Auth Key (recommended)
   - Or upload APNs Certificate
3. Download APNs key from Apple Developer Portal
4. Upload to Firebase

## Step 10: Update Info.plist

Add location permission:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to display it on your profile and show relevant local ads.</string>
```

## Verification Checklist

- [ ] Firebase project created
- [ ] iOS app added to Firebase
- [ ] `GoogleService-Info.plist` added to Xcode project
- [ ] Firebase SDK installed
- [ ] Firebase initialized in app
- [ ] Email/Password auth enabled
- [ ] Firestore database created
- [ ] Security rules configured
- [ ] Storage enabled (for later)
- [ ] Cloud Messaging configured (for later)

## Testing

1. Run the app
2. Try signing up with a test email
3. Check Firebase Console → Authentication for new user
4. Check Firestore → users collection for user document
5. Verify email verification email is sent
