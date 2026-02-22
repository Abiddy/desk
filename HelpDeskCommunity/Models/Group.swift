//
//  Group.swift
//  HelpDeskCommunity
//
//  Created on Feb 12, 2026.
//

import Foundation
import SwiftData

enum GroupCategory: String, Codable, CaseIterable {
    case classifieds = "Classifieds"
    case attorneys = "Attorneys"
    case doctors = "Doctors"
    case professionals = "Professionals"
    case education = "Education"
    case giveaway = "Giveaway"
}

@Model
final class Group {
    @Attribute(.unique) var id: String
    var name: String
    var imageURL: String? // Combination of country flag + HelpDesk logo
    var country: String
    var category: String // GroupCategory rawValue
    var memberCount: Int
    var moderators: [String] // Array of user IDs
    var wordFilters: [String] // Array of filtered words
    var createdAt: Date
    var lastMessageAt: Date?
    
    init(
        id: String = UUID().uuidString,
        name: String,
        imageURL: String? = nil,
        country: String,
        category: String,
        memberCount: Int = 0,
        moderators: [String] = [],
        wordFilters: [String] = [],
        createdAt: Date = Date(),
        lastMessageAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
        self.country = country
        self.category = category
        self.memberCount = memberCount
        self.moderators = moderators
        self.wordFilters = wordFilters
        self.createdAt = createdAt
        self.lastMessageAt = lastMessageAt
    }
}
