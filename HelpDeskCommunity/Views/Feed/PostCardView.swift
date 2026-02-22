//
//  PostCardView.swift
//  HelpDeskCommunity
//

import SwiftUI
import FirebaseAuth

struct PostCardView: View {
    let post: Post
    var onLike: () -> Void = {}
    var onComment: () -> Void = {}
    var onShare: () -> Void = {}
    var onGroupTap: (() -> Void)? = nil
    var onAuthorTap: (() -> Void)? = nil

    private var currentUserId: String {
        Auth.auth().currentUser?.uid ?? ""
    }

    private var isLiked: Bool {
        post.likes.contains(currentUserId)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top row: author (left) + group pill (right)
            HStack(alignment: .center) {
                Button(action: { onAuthorTap?() }) {
                    HStack(spacing: 8) {
                        // Avatar
                        if let pic = post.authorProfilePic, !pic.isEmpty {
                            AsyncImage(url: URL(string: pic)) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                            }
                            .frame(width: 36, height: 36)
                            .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 36, height: 36)
                                .foregroundColor(.gray)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(post.authorName)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text(post.timestamp, style: .relative)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                // Group category pill
                if let onGroupTap = onGroupTap {
                    Button(action: onGroupTap) {
                        Text(post.groupCategory)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.purple.opacity(0.2))
                            .foregroundColor(.purple)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text(post.groupCategory)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.2))
                        .foregroundColor(.purple)
                        .cornerRadius(12)
                }
            }

            // Title + body
            VStack(alignment: .leading, spacing: 4) {
                if !post.title.isEmpty {
                    Text(post.title)
                        .font(.headline)
                }
                if !post.body.isEmpty {
                    Text(post.body)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(4)
                }
            }

            // Optional image (moderator posts)
            if let imageURL = post.imageURL, !imageURL.isEmpty {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 180)
                }
                .frame(maxWidth: .infinity, maxHeight: 220)
                .clipped()
                .cornerRadius(10)
            }

            // Bottom row: like, comment, share
            HStack(spacing: 24) {
                Button(action: onLike) {
                    HStack(spacing: 4) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : .secondary)
                        Text("\(post.likes.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)

                Button(action: onComment) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left")
                            .foregroundColor(.secondary)
                        Text("\(post.commentCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)

                Button(action: onShare) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.secondary)
                        Text("\(post.shareCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(14)
    }
}
