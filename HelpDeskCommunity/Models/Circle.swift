//
//  Circle.swift
//  Helpdecks
//

import Foundation
import SwiftData

enum CircleCategory: String, Codable, CaseIterable, Identifiable {
    case tech = "Tech"
    case medical = "Medical"
    case legal = "Legal"
    case business = "Business"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .tech: return "desktopcomputer"
        case .medical: return "cross.case.fill"
        case .legal: return "scalemass.fill"
        case .business: return "briefcase.fill"
        }
    }

    var color: String {
        switch self {
        case .tech: return "blue"
        case .medical: return "red"
        case .legal: return "orange"
        case .business: return "purple"
        }
    }
}

@Model
final class Circle {
    @Attribute(.unique) var id: String
    var name: String
    var circleDescription: String
    var iconName: String
    var category: String
    var creatorId: String?
    var adminIds: [String]
    var memberIds: [String]
    var followerCount: Int
    var isPromoted: Bool
    var inviteCode: String?
    var isPublic: Bool
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        name: String,
        circleDescription: String = "",
        iconName: String = "circle.grid.3x3.fill",
        category: String = "",
        creatorId: String? = nil,
        adminIds: [String] = [],
        memberIds: [String] = [],
        followerCount: Int = 0,
        isPromoted: Bool = false,
        inviteCode: String? = nil,
        isPublic: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.circleDescription = circleDescription
        self.iconName = iconName
        self.category = category
        self.creatorId = creatorId
        self.adminIds = adminIds
        self.memberIds = memberIds
        self.followerCount = followerCount
        self.isPromoted = isPromoted
        self.inviteCode = inviteCode
        self.isPublic = isPublic
        self.createdAt = createdAt
    }
}
