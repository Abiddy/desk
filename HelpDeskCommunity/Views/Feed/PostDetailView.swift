//
//  PostDetailView.swift
//  Helpdecks
//

import SwiftUI

struct PostDetailView: View {
    let post: Post
    @EnvironmentObject var followService: FollowService
    @State private var comments: [Comment] = []
    @State private var newCommentText = ""
    @State private var isLoading = false
    private let postService = PostService()

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    postHeader
                    postBody

                    Divider()

                    followRow

                    Divider()

                    Text("Comments (\(comments.count))")
                        .font(.headline)
                        .padding(.horizontal)

                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if comments.isEmpty {
                        Text("No comments yet. Be the first!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    } else {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(comments, id: \.id) { comment in
                                CommentRow(comment: comment)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }

            commentInputBar
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadComments() }
    }

    private var postHeader: some View {
        HStack {
            HStack(spacing: 8) {
                postAuthorAvatar
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.authorName)
                        .font(.subheadline).fontWeight(.semibold)
                    Text(post.timestamp, style: .relative)
                        .font(.caption2).foregroundColor(.secondary)
                }
            }
            Spacer()
            Text(post.circleName)
                .font(.caption).fontWeight(.medium)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(Color.blue.opacity(0.15))
                .foregroundColor(.blue)
                .cornerRadius(12)
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var postAuthorAvatar: some View {
        Group {
            if let pic = post.authorProfilePic, !pic.isEmpty {
                AsyncImage(url: URL(string: pic)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Image(systemName: "person.fill").resizable().foregroundColor(Color(.systemGray3))
                }
                .clipShape(SwiftUI.Circle())
            } else {
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundColor(Color(.systemGray3))
            }
        }
        .frame(width: 32, height: 32)
        .background(Color(.systemGray5))
        .clipShape(SwiftUI.Circle())
    }

    private var postBody: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !post.title.isEmpty {
                Text(post.title).font(.title3).fontWeight(.bold)
            }
            if !post.body.isEmpty {
                Text(post.body).font(.body)
            }
            if let url = post.imageURL, !url.isEmpty {
                AsyncImage(url: URL(string: url)) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    Rectangle().fill(Color(.systemGray5)).frame(height: 200)
                }
                .frame(maxWidth: .infinity, maxHeight: 240)
                .clipped().cornerRadius(10)
            }
        }
        .padding(.horizontal)
    }

    private var followRow: some View {
        HStack {
            Text(post.authorName)
                .font(.subheadline).fontWeight(.medium)
            Spacer()
            Button {
                Task { await followService.toggleFollow(post.authorId) }
            } label: {
                Text(followService.isFollowing(post.authorId) ? "Following" : "Follow")
                    .font(.subheadline).fontWeight(.semibold)
                    .padding(.horizontal, 16).padding(.vertical, 6)
                    .background(followService.isFollowing(post.authorId) ? Color(.systemGray4) : Color.blue)
                    .foregroundColor(followService.isFollowing(post.authorId) ? .primary : .white)
                    .cornerRadius(16)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
    }

    private var commentInputBar: some View {
        HStack(spacing: 8) {
            TextField("Add a comment...", text: $newCommentText)
                .textFieldStyle(.roundedBorder)
            Button { Task { await submitComment() } } label: {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(newCommentText.isEmpty ? .gray : .blue)
            }
            .disabled(newCommentText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.white)
    }

    private func loadComments() async {
        isLoading = true
        do {
            comments = try await postService.fetchComments(postId: post.id)
        } catch {
            #if DEBUG
            print("[PostDetailView] loadComments error: \(error)")
            #endif
        }
        isLoading = false
    }

    private func submitComment() async {
        let text = newCommentText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        do {
            let comment = try await postService.addComment(postId: post.id, text: text)
            comments.append(comment)
            newCommentText = ""
        } catch {
            #if DEBUG
            print("[PostDetailView] submitComment error: \(error)")
            #endif
        }
    }
}

struct CommentRow: View {
    let comment: Comment

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            commentAuthorAvatar

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.authorName)
                        .font(.caption).fontWeight(.semibold)
                    Text(comment.timestamp, style: .relative)
                        .font(.caption2).foregroundColor(.secondary)
                }
                Text(comment.text)
                    .font(.subheadline)
            }
        }
    }

    @ViewBuilder
    private var commentAuthorAvatar: some View {
        Group {
            if let pic = comment.authorProfilePic, !pic.isEmpty {
                AsyncImage(url: URL(string: pic)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Image(systemName: "person.fill").resizable().scaledToFit().frame(width: 14, height: 14).foregroundColor(Color(.systemGray3))
                }
                .clipShape(SwiftUI.Circle())
            } else {
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
                    .foregroundColor(Color(.systemGray3))
            }
        }
        .frame(width: 28, height: 28)
        .background(Color(.systemGray5))
        .clipShape(SwiftUI.Circle())
    }
}
