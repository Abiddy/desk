//
//  Message.swift
//  HelpDeskCommunity
//
//  Created on Feb 12, 2026.
//

import Foundation
import SwiftData

enum MessageType: String, Codable {
    case text = "text"
    case image = "image"
    case video = "video"
    case audio = "audio"
    case link = "link"
    case announcement = "announcement"
}

@Model
final class Message {
    @Attribute(.unique) var id: String
    var groupId: String? // nil for private messages
    var chatId: String? // For private 1-on-1 chats
    var senderId: String
    var senderName: String
    var text: String
    var type: String // MessageType rawValue
    var mediaURL: String? // For images, videos, audio
    var timestamp: Date
    var readBy: [String] // Array of user IDs who read the message
    var isAnnouncement: Bool
    
    init(
        id: String = UUID().uuidString,
        groupId: String? = nil,
        chatId: String? = nil,
        senderId: String,
        senderName: String,
        text: String,
        type: String = MessageType.text.rawValue,
        mediaURL: String? = nil,
        timestamp: Date = Date(),
        readBy: [String] = [],
        isAnnouncement: Bool = false
    ) {
        self.id = id
        self.groupId = groupId
        self.chatId = chatId
        self.senderId = senderId
        self.senderName = senderName
        self.text = text
        self.type = type
        self.mediaURL = mediaURL
        self.timestamp = timestamp
        self.readBy = readBy
        self.isAnnouncement = isAnnouncement
    }
}
