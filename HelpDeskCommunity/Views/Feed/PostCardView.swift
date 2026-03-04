//
//  PostCardView.swift
//  Helpdecks
//

import SwiftUI
import FirebaseAuth

struct PostCardView: View {
    let post: Post
    var onLike: () -> Void = {}
    var onComment: () -> Void = {}
    var onShare: () -> Void = {}
    var onCircleTap: (() -> Void)? = nil
    var onAuthorTap: (() -> Void)? = nil

    private var currentUserId: String {
        Auth.auth().currentUser?.uid ?? ""
    }

    private var isLiked: Bool {
        post.likes.contains(currentUserId)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: avatar + name + time + menu
            HStack(alignment: .center, spacing: 10) {
                avatarView

                VStack(alignment: .leading, spacing: 2) {
                    Text(post.authorName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    HStack(spacing: 4) {
                        Text(post.circleName)
                            .font(.caption2)
                            .foregroundColor(.blue)
                        Text("·")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(post.timestamp, style: .relative)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            // Content
            VStack(alignment: .leading, spacing: 6) {
                if !post.title.isEmpty {
                    Text(post.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                if !post.body.isEmpty {
                    Text(post.body)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(4)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            // Optional image
            if let imageURL = post.imageURL, !imageURL.isEmpty {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Rectangle().fill(Color(.systemGray5)).frame(height: 180)
                }
                .frame(maxWidth: .infinity, maxHeight: 220)
                .clipped()
            }

            // Reactions row
            HStack(spacing: 6) {
                if post.likes.count > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "heart.fill")
                            .font(.caption2)
                            .foregroundColor(.red)
                        Text("\(post.likes.count)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                if post.commentCount > 0 {
                    Text("\(post.commentCount) replies")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            // Action buttons
            HStack(spacing: 0) {
                actionButton(icon: isLiked ? "heart.fill" : "heart",
                             label: "Like",
                             color: isLiked ? .red : .secondary,
                             action: onLike)

                actionButton(icon: "bubble.left",
                             label: "Reply",
                             color: .secondary,
                             action: onComment)

                actionButton(icon: "square.and.arrow.up",
                             label: "Share",
                             color: .secondary,
                             action: onShare)
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private var avatarView: some View {
        Group {
            if let pic = post.authorProfilePic, !pic.isEmpty {
                AsyncImage(url: URL(string: pic)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Image(systemName: "person.fill").resizable().scaledToFit().frame(width: 16, height: 16).foregroundColor(Color(.systemGray3))
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

    private func actionButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(label)
                    .font(.caption)
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}
