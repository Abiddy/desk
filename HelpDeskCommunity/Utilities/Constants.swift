//
//  Constants.swift
//  HelpDeskCommunity
//
//  Created on Feb 12, 2026.
//

import Foundation

struct Constants {
    // UserDefaults Keys
    struct UserDefaultsKeys {
        static let ndaAccepted = "ndaAccepted"
        static let hasSeenOnboarding = "hasSeenOnboarding"
    }
    
    // Firestore Collections
    struct FirestoreCollections {
        static let users = "users"
        static let groups = "groups"
        static let messages = "messages"
        static let privateChats = "privateChats"
    }
    
    // App Info
    struct AppInfo {
        static let appName = "Help Desk Community"
        static let supportEmail = "support@helpdeskcommunity.com"
    }
}
