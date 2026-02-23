//
//  Deck.swift
//  HelpDeskCommunity
//

import Foundation
import SwiftData

enum DeckType: String, Codable {
    case system
    case userPublic
    case userPrivate
}

@Model
final class Deck {
    @Attribute(.unique) var id: String
    var name: String
    var deckDescription: String
    var iconName: String
    var type: String
    var creatorId: String?
    var adminIds: [String]
    var memberIds: [String]
    var inviteCode: String?
    var isPublic: Bool
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        name: String,
        deckDescription: String = "",
        iconName: String = "rectangle.stack.fill",
        type: String = DeckType.userPublic.rawValue,
        creatorId: String? = nil,
        adminIds: [String] = [],
        memberIds: [String] = [],
        inviteCode: String? = nil,
        isPublic: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.deckDescription = deckDescription
        self.iconName = iconName
        self.type = type
        self.creatorId = creatorId
        self.adminIds = adminIds
        self.memberIds = memberIds
        self.inviteCode = inviteCode
        self.isPublic = isPublic
        self.createdAt = createdAt
    }
}
