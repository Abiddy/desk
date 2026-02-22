//
//  Comment.swift
//  HelpDeskCommunity
//

import Foundation
import SwiftData

@Model
final class Comment {
    @Attribute(.unique) var id: String
    var postId: String
    var authorId: String
    var authorName: String
    var authorProfilePic: String?
    var text: String
    var timestamp: Date

    init(
        id: String = UUID().uuidString,
        postId: String,
        authorId: String,
        authorName: String,
        authorProfilePic: String? = nil,
        text: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.postId = postId
        self.authorId = authorId
        self.authorName = authorName
        self.authorProfilePic = authorProfilePic
        self.text = text
        self.timestamp = timestamp
    }
}
