//
//  GroupFeedView.swift
//  HelpDeskCommunity
//

import SwiftUI

struct GroupFeedView: View {
    let groupCategory: String
    @StateObject private var feedViewModel = FeedViewModel()
    @EnvironmentObject var followService: FollowService

    var body: some View {
        ScrollView {
            if feedViewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
            } else if feedViewModel.posts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No posts in \(groupCategory) yet.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(feedViewModel.posts, id: \.id) { post in
                        NavigationLink(destination: PostDetailView(post: post)) {
                            PostCardView(
                                post: post,
                                onLike: { Task { await feedViewModel.toggleLike(postId: post.id) } },
                                onComment: {},
                                onShare: { Task { await feedViewModel.incrementShare(postId: post.id) } }
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
        }
        .navigationTitle(groupCategory)
        .navigationBarTitleDisplayMode(.large)
        .task {
            await feedViewModel.loadGroupFeed(groupCategory: groupCategory)
        }
    }
}
