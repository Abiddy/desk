//
//  Post.swift
//  Helpdecks
//

import Foundation
import SwiftData

@Model
final class Post {
    @Attribute(.unique) var id: String
    var circleId: String
    var circleName: String
    var authorId: String
    var authorName: String
    var authorProfilePic: String?
    var title: String
    var body: String
    var imageURL: String?
    var likes: [String]
    var commentCount: Int
    var shareCount: Int
    var timestamp: Date

    init(
        id: String = UUID().uuidString,
        circleId: String,
        circleName: String,
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
        self.circleId = circleId
        self.circleName = circleName
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
