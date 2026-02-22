//
//  User.swift
//  HelpDeskCommunity
//
//  Created on Feb 12, 2026.
//

import Foundation
import SwiftData

@Model
final class User {
    @Attribute(.unique) var id: String
    var email: String
    var name: String
    var profilePictureURL: String?
    var location: String?
    var latitude: Double?
    var longitude: Double?
    var isEmailVerified: Bool
    var createdAt: Date
    var lastSeen: Date
    var blockedUsers: [String]
    var followingUserIds: [String]
    var joinedGroupIds: [String]
    var notificationSettings: NotificationSettings?
    var chatSettings: ChatSettings?
    
    init(
        id: String = UUID().uuidString,
        email: String,
        name: String,
        profilePictureURL: String? = nil,
        location: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        isEmailVerified: Bool = false,
        createdAt: Date = Date(),
        lastSeen: Date = Date(),
        blockedUsers: [String] = [],
        followingUserIds: [String] = [],
        joinedGroupIds: [String] = [],
        notificationSettings: NotificationSettings? = nil,
        chatSettings: ChatSettings? = nil
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.profilePictureURL = profilePictureURL
        self.location = location
        self.latitude = latitude
        self.longitude = longitude
        self.isEmailVerified = isEmailVerified
        self.createdAt = createdAt
        self.lastSeen = lastSeen
        self.blockedUsers = blockedUsers
        self.followingUserIds = followingUserIds
        self.joinedGroupIds = joinedGroupIds
        self.notificationSettings = notificationSettings
        self.chatSettings = chatSettings
    }
}

// MARK: - Supporting Models
struct NotificationSettings: Codable {
    var pushEnabled: Bool = true
    var soundEnabled: Bool = true
    var groupNotificationsEnabled: Bool = true
    var privateMessageNotificationsEnabled: Bool = true
}

struct ChatSettings: Codable {
    var readReceiptsEnabled: Bool = true
    var typingIndicatorsEnabled: Bool = true
    var lastSeenEnabled: Bool = true
}
