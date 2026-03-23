//
//  FeedViewModel.swift
//  Helpdecks
//

import Foundation
import SwiftUI
import FirebaseAuth

@MainActor
class FeedViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let postService = PostService()

    func loadFeed(joinedCircleIds: [String], followingUserIds: [String]) async {
        isLoading = true
        errorMessage = nil
        do {
            posts = try await postService.fetchFeed(
                joinedCircleIds: joinedCircleIds,
                followingUserIds: followingUserIds
            )
        } catch {
            errorMessage = error.localizedDescription
            #if DEBUG
            print("[FeedViewModel] loadFeed error: \(error)")
            #endif
        }
        isLoading = false
    }

    func loadExploreFeed() async {
        isLoading = true
        errorMessage = nil
        do {
            posts = try await postService.fetchExplorePosts()
        } catch {
            errorMessage = error.localizedDescription
            #if DEBUG
            print("[FeedViewModel] loadExploreFeed error: \(error)")
            #endif
        }
        isLoading = false
    }

    func loadCircleFeed(circleName: String) async {
        isLoading = true
        errorMessage = nil
        do {
            posts = try await postService.fetchCirclePosts(circleName: circleName)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func filteredPosts(for circleName: String?) -> [Post] {
        guard let name = circleName else { return posts }
        return posts.filter { $0.circleName.lowercased() == name.lowercased() }
    }

    // MARK: - Interactions

    func toggleLike(postId: String) async {
        do {
            try await postService.toggleLike(postId: postId)
            if let idx = posts.firstIndex(where: { $0.id == postId }) {
                let userId = Auth.auth().currentUser?.uid ?? ""
                if posts[idx].likes.contains(userId) {
                    posts[idx].likes.removeAll { $0 == userId }
                } else {
                    posts[idx].likes.append(userId)
                }
            }
        } catch {
            #if DEBUG
            print("[FeedViewModel] toggleLike error: \(error)")
            #endif
        }
    }

    func incrementShare(postId: String) async {
        do {
            try await postService.incrementShareCount(postId: postId)
            if let idx = posts.firstIndex(where: { $0.id == postId }) {
                posts[idx].shareCount += 1
            }
        } catch {
            #if DEBUG
            print("[FeedViewModel] incrementShare error: \(error)")
            #endif
        }
    }

    func createPost(circleId: String, circleName: String, title: String, body: String) async -> Bool {
        do {
            let newPost = try await postService.createPost(
                circleId: circleId,
                circleName: circleName,
                title: title,
                body: body
            )
            posts.insert(newPost, at: 0)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
