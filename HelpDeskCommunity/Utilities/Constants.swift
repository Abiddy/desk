//
//  Constants.swift
//  Helpdecks
//

import Foundation

struct Constants {
    struct UserDefaultsKeys {
        static let ndaAccepted = "ndaAccepted"
        static let hasSeenOnboarding = "hasSeenOnboarding"
    }

    struct FirestoreCollections {
        static let users = "users"
        static let circles = "circles"
        static let messages = "messages"
        static let privateChats = "privateChats"
        static let posts = "posts"
        static let helpCards = "helpCards"
    }

    struct AppInfo {
        static let appName = "Helpdecks"
        static let supportEmail = "support@helpdecks.com"
    }
}
