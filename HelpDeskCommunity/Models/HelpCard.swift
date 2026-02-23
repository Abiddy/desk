//
//  HelpCard.swift
//  HelpDeskCommunity
//

import Foundation
import SwiftData

enum HelpCardSkill: String, Codable, CaseIterable, Identifiable {
    case rides = "Rides"
    case tutoring = "Tutoring"
    case groceries = "Groceries"
    case techHelp = "Tech Help"
    case jobReferrals = "Job Referrals"
    case legal = "Legal"
    case medical = "Medical"
    case moving = "Moving"
    case repairs = "Repairs"
    case childcare = "Childcare"
    case translation = "Translation"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .rides: return "car.fill"
        case .tutoring: return "book.fill"
        case .groceries: return "cart.fill"
        case .techHelp: return "desktopcomputer"
        case .jobReferrals: return "briefcase.fill"
        case .legal: return "scalemass.fill"
        case .medical: return "cross.case.fill"
        case .moving: return "box.truck.fill"
        case .repairs: return "wrench.and.screwdriver.fill"
        case .childcare: return "figure.and.child.holdinghands"
        case .translation: return "character.bubble.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

enum HelpCardStatus: String, Codable {
    case open
    case matched
    case closed
}

enum HelpCardUrgency: String, Codable, CaseIterable {
    case normal = "Normal"
    case urgent = "Urgent Today"
}

@Model
final class HelpCard {
    @Attribute(.unique) var id: String
    var authorId: String
    var authorName: String
    var authorProfilePic: String?
    var title: String
    var cardDescription: String
    var skill: String
    var urgency: String
    var isRemote: Bool
    var latitude: Double?
    var longitude: Double?
    var locationName: String?
    var deckId: String?
    var status: String
    var swipedRightUserIds: [String]
    var swipedLeftUserIds: [String]
    var timestamp: Date
    var expiresAt: Date?

    init(
        id: String = UUID().uuidString,
        authorId: String,
        authorName: String,
        authorProfilePic: String? = nil,
        title: String,
        cardDescription: String,
        skill: String = HelpCardSkill.other.rawValue,
        urgency: String = HelpCardUrgency.normal.rawValue,
        isRemote: Bool = false,
        latitude: Double? = nil,
        longitude: Double? = nil,
        locationName: String? = nil,
        deckId: String? = nil,
        status: String = HelpCardStatus.open.rawValue,
        swipedRightUserIds: [String] = [],
        swipedLeftUserIds: [String] = [],
        timestamp: Date = Date(),
        expiresAt: Date? = nil
    ) {
        self.id = id
        self.authorId = authorId
        self.authorName = authorName
        self.authorProfilePic = authorProfilePic
        self.title = title
        self.cardDescription = cardDescription
        self.skill = skill
        self.urgency = urgency
        self.isRemote = isRemote
        self.latitude = latitude
        self.longitude = longitude
        self.locationName = locationName
        self.deckId = deckId
        self.status = status
        self.swipedRightUserIds = swipedRightUserIds
        self.swipedLeftUserIds = swipedLeftUserIds
        self.timestamp = timestamp
        self.expiresAt = expiresAt
    }
}
