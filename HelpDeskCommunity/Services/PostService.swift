//
//  PostService.swift
//  HelpDeskCommunity
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
class PostService: ObservableObject {
    private let db = Firestore.firestore()
    private var postsCollection: CollectionReference { db.collection("posts") }

    // MARK: - Create

    func createPost(
        groupId: String,
        groupCategory: String,
        title: String,
        body: String,
        imageURL: String? = nil
    ) async throws -> Post {
        guard let user = Auth.auth().currentUser else { throw PostError.notAuthenticated }

        let userDoc = try await db.collection("users").document(user.uid).getDocument()
        let userName = userDoc.data()?["name"] as? String ?? "Unknown"
        let userPic = userDoc.data()?["profilePictureURL"] as? String

        let post = Post(
            groupId: groupId,
            groupCategory: groupCategory,
            authorId: user.uid,
            authorName: userName,
            authorProfilePic: userPic,
            title: title,
            body: body,
            imageURL: imageURL
        )

        let data: [String: Any] = [
            "id": post.id,
            "groupId": post.groupId,
            "groupCategory": post.groupCategory,
            "authorId": post.authorId,
            "authorName": post.authorName,
            "authorProfilePic": post.authorProfilePic as Any,
            "title": post.title,
            "body": post.body,
            "imageURL": post.imageURL as Any,
            "likes": post.likes,
            "commentCount": post.commentCount,
            "shareCount": post.shareCount,
            "timestamp": Timestamp(date: post.timestamp)
        ]

        try await postsCollection.document(post.id).setData(data)
        return post
    }

    // MARK: - Read (feed)

    /// Posts from joined groups OR from followed users, sorted by time desc.
    func fetchFeed(joinedGroupIds: [String], followingUserIds: [String], limit: Int = 50) async throws -> [Post] {
        var allPosts: [Post] = []

        // Source 1: posts from joined groups
        if !joinedGroupIds.isEmpty {
            let groupSnapshot = try await postsCollection
                .whereField("groupCategory", in: joinedGroupIds.map { $0.capitalized })
                .order(by: "timestamp", descending: true)
                .limit(to: limit)
                .getDocuments()
            allPosts.append(contentsOf: groupSnapshot.documents.compactMap { postFromDocument($0) })
        }

        // Source 2: posts from followed users (may overlap)
        if !followingUserIds.isEmpty {
            let userSnapshot = try await postsCollection
                .whereField("authorId", in: followingUserIds)
                .order(by: "timestamp", descending: true)
                .limit(to: limit)
                .getDocuments()
            allPosts.append(contentsOf: userSnapshot.documents.compactMap { postFromDocument($0) })
        }

        // Deduplicate by id and sort
        var seen = Set<String>()
        let unique = allPosts.filter { seen.insert($0.id).inserted }
        return unique.sorted { $0.timestamp > $1.timestamp }
    }

    /// Posts for a single group category.
    func fetchGroupPosts(groupCategory: String, limit: Int = 50) async throws -> [Post] {
        let snapshot = try await postsCollection
            .whereField("groupCategory", isEqualTo: groupCategory)
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
            .getDocuments()
        return snapshot.documents.compactMap { postFromDocument($0) }
    }

    // MARK: - Like / Unlike

    func toggleLike(postId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { throw PostError.notAuthenticated }

        let ref = postsCollection.document(postId)
        let doc = try await ref.getDocument()
        guard let likes = doc.data()?["likes"] as? [String] else { return }

        if likes.contains(userId) {
            try await ref.updateData(["likes": FieldValue.arrayRemove([userId])])
        } else {
            try await ref.updateData(["likes": FieldValue.arrayUnion([userId])])
        }
    }

    // MARK: - Comments

    func addComment(postId: String, text: String) async throws -> Comment {
        guard let user = Auth.auth().currentUser else { throw PostError.notAuthenticated }

        let userDoc = try await db.collection("users").document(user.uid).getDocument()
        let userName = userDoc.data()?["name"] as? String ?? "Unknown"
        let userPic = userDoc.data()?["profilePictureURL"] as? String

        let comment = Comment(
            postId: postId,
            authorId: user.uid,
            authorName: userName,
            authorProfilePic: userPic,
            text: text
        )

        let data: [String: Any] = [
            "id": comment.id,
            "postId": comment.postId,
            "authorId": comment.authorId,
            "authorName": comment.authorName,
            "authorProfilePic": comment.authorProfilePic as Any,
            "text": comment.text,
            "timestamp": Timestamp(date: comment.timestamp)
        ]

        try await postsCollection.document(postId)
            .collection("comments").document(comment.id).setData(data)

        // Increment commentCount on the post
        try await postsCollection.document(postId)
            .updateData(["commentCount": FieldValue.increment(Int64(1))])

        return comment
    }

    func fetchComments(postId: String) async throws -> [Comment] {
        let snapshot = try await postsCollection.document(postId)
            .collection("comments")
            .order(by: "timestamp", descending: false)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            let d = doc.data()
            return Comment(
                id: d["id"] as? String ?? doc.documentID,
                postId: d["postId"] as? String ?? postId,
                authorId: d["authorId"] as? String ?? "",
                authorName: d["authorName"] as? String ?? "Unknown",
                authorProfilePic: d["authorProfilePic"] as? String,
                text: d["text"] as? String ?? "",
                timestamp: (d["timestamp"] as? Timestamp)?.dateValue() ?? Date()
            )
        }
    }

    // MARK: - Share (increment counter)

    func incrementShareCount(postId: String) async throws {
        try await postsCollection.document(postId)
            .updateData(["shareCount": FieldValue.increment(Int64(1))])
    }

    // MARK: - Helpers

    private func postFromDocument(_ doc: QueryDocumentSnapshot) -> Post? {
        let d = doc.data()
        return Post(
            id: d["id"] as? String ?? doc.documentID,
            groupId: d["groupId"] as? String ?? "",
            groupCategory: d["groupCategory"] as? String ?? "",
            authorId: d["authorId"] as? String ?? "",
            authorName: d["authorName"] as? String ?? "Unknown",
            authorProfilePic: d["authorProfilePic"] as? String,
            title: d["title"] as? String ?? "",
            body: d["body"] as? String ?? "",
            imageURL: d["imageURL"] as? String,
            likes: d["likes"] as? [String] ?? [],
            commentCount: d["commentCount"] as? Int ?? 0,
            shareCount: d["shareCount"] as? Int ?? 0,
            timestamp: (d["timestamp"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}

enum PostError: LocalizedError {
    case notAuthenticated
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "You must be signed in."
        case .permissionDenied: return "You don't have permission for this action."
        }
    }
}
