//
//  FeedViewModel.swift
//  HelpDeskCommunity
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

    /// Load the Home feed from joined groups + followed users.
    func loadFeed(joinedGroupIds: [String], followingUserIds: [String]) async {
        isLoading = true
        errorMessage = nil
        do {
            posts = try await postService.fetchFeed(
                joinedGroupIds: joinedGroupIds,
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

    /// Load posts for a single group category (standalone group page).
    func loadGroupFeed(groupCategory: String) async {
        isLoading = true
        errorMessage = nil
        do {
            posts = try await postService.fetchGroupPosts(groupCategory: groupCategory)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// Filter current posts by group category (client-side).
    func filteredPosts(for groupCategory: String?) -> [Post] {
        guard let category = groupCategory else { return posts }
        return posts.filter { $0.groupCategory.lowercased() == category.lowercased() }
    }

    // MARK: - Interactions

    func toggleLike(postId: String) async {
        do {
            try await postService.toggleLike(postId: postId)
            // Optimistic: toggle in local list
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

    func createPost(groupId: String, groupCategory: String, title: String, body: String) async -> Bool {
        do {
            let newPost = try await postService.createPost(
                groupId: groupId,
                groupCategory: groupCategory,
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
