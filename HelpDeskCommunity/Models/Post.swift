//
//  Post.swift
//  HelpDeskCommunity
//

import Foundation
import SwiftData

@Model
final class Post {
    @Attribute(.unique) var id: String
    var groupId: String
    var groupCategory: String // GroupCategory rawValue
    var authorId: String
    var authorName: String
    var authorProfilePic: String?
    var title: String
    var body: String
    var imageURL: String? // Only moderators can attach images
    var likes: [String] // User IDs who liked
    var commentCount: Int
    var shareCount: Int
    var timestamp: Date

    init(
        id: String = UUID().uuidString,
        groupId: String,
        groupCategory: String,
        authorId: String,
        authorName: String,
        authorProfilePic: String? = nil,
        title: String,
        body: String,
        imageURL: String? = nil,
        likes: [String] = [],
        commentCount: Int = 0,
        shareCount: Int = 0,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.groupId = groupId
        self.groupCategory = groupCategory
        self.authorId = authorId
        self.authorName = authorName
        self.authorProfilePic = authorProfilePic
        self.title = title
        self.body = body
        self.imageURL = imageURL
        self.likes = likes
        self.commentCount = commentCount
        self.shareCount = shareCount
        self.timestamp = timestamp
    }
}
