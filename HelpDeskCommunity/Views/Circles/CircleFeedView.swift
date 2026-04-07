//
//  CircleFeedView.swift
//  Helpdecks
//

import SwiftUI

struct CircleFeedView: View {
    let circle: Circle
    @StateObject private var feedViewModel = FeedViewModel()
    @StateObject private var helpCardService = HelpCardService()
    @EnvironmentObject var followService: FollowService
    @EnvironmentObject var joinedCirclesStore: JoinedCirclesStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    @State private var deckCards: [HelpCard] = []
    @State private var isDeckLoading = true
    @State private var deckCurrentIndex = 0

    private var isJoined: Bool {
        joinedCirclesStore.isJoined(circle.name)
    }

    var body: some View {
        Group {
            if selectedTab == 0 {
                feedTab
            } else {
                decksTab
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                HStack(spacing: 8) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.blue)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(circle.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Text("\(circle.followerCount) followers")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Picker("", selection: $selectedTab) {
                    Text("Feed").tag(0)
                    Text("Decks").tag(1)
                }
                .pickerStyle(.segmented)
                .frame(width: 128)

                Button {
                    joinedCirclesStore.toggle(circle.name)
                } label: {
                    Text(isJoined ? "Joined" : "Join")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(isJoined ? Color(.systemGray5) : Color.blue)
                        .foregroundColor(isJoined ? .primary : .white)
                        .cornerRadius(16)
                }
            }
        }
        .task {
            await feedViewModel.loadCircleFeed(circleName: circle.name)
            await loadDeckCards()
        }
    }

    // MARK: - Feed Tab

    private var feedTab: some View {
        ScrollView {
            if feedViewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
            } else if feedViewModel.posts.isEmpty {
                emptyFeedState
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(Array(feedViewModel.posts.enumerated()), id: \.element.id) { index, post in
                        VStack(spacing: 0) {
                            NavigationLink(destination: PostDetailView(post: post)) {
                                PostCardView(
                                    post: post,
                                    onPromote: { Task { await feedViewModel.toggleLike(postId: post.id) } },
                                    onComment: {},
                                    onShare: { Task { await feedViewModel.incrementShare(postId: post.id) } }
                                )
                            }
                            .buttonStyle(.plain)
                            if index < feedViewModel.posts.count - 1 {
                                Divider()
                                    .padding(.leading, 56)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
        }
        .refreshable {
            await feedViewModel.loadCircleFeed(circleName: circle.name)
        }
    }

    private var emptyFeedState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("No posts in \(circle.name) yet.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    // MARK: - Decks Tab (swipeable cards, no scrolling list)

    private var decksTab: some View {
        Group {
            if isDeckLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if deckCards.isEmpty {
                emptyDeckState
            } else if deckCurrentIndex >= deckCards.count {
                allCaughtUpState
            } else {
                deckSwipeContent(card: deckCards[deckCurrentIndex])
            }
        }
        .background(Color(red: 0.97, green: 0.96, blue: 0.94))
        .refreshable {
            await loadDeckCards()
        }
    }

    @ViewBuilder
    private func deckSwipeContent(card: HelpCard) -> some View {
        let skill = HelpCardSkill(rawValue: card.skill) ?? .other
        VStack(spacing: 20) {
            // Progress dots
            HStack(spacing: 6) {
                ForEach(0..<min(deckCards.count, 10), id: \.self) { i in
                    SwiftUI.Circle()
                        .fill(i == deckCurrentIndex ? Color.blue : Color(.systemGray4))
                        .frame(width: 8, height: 8)
                }
                if deckCards.count > 10 {
                    Text("+\(deckCards.count - 10)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)

            // Card
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label(skill.rawValue, systemImage: skill.icon)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.blue.opacity(0.12))
                        .foregroundColor(.blue)
                        .cornerRadius(8)

                    if card.urgency == HelpCardUrgency.urgent.rawValue {
                        Label("Urgent", systemImage: "flame.fill")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.red.opacity(0.12))
                            .foregroundColor(.red)
                            .cornerRadius(8)
                    }

                    Spacer()
                }

                Text(card.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)

                Text(card.cardDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)

                Spacer()

                HStack(spacing: 10) {
                    deckAuthorAvatar(card: card)
                        .frame(width: 28, height: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(card.authorName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        if let locName = card.locationName {
                            Text(locName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    Text(card.timestamp, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, minHeight: 320)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
            .padding(.horizontal, 20)

            Spacer()

            // Bottom buttons
            HStack {
                Button {
                    deckGoBack()
                } label: {
                    Text("Back")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                }
                .disabled(deckCurrentIndex == 0)
                .opacity(deckCurrentIndex == 0 ? 0.4 : 1.0)

                Spacer()

                Button {
                    deckHelpAction(card: card)
                } label: {
                    Text("I can help!")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(Color.green)
                        .cornerRadius(24)
                }
            }
            .padding(.horizontal, 24)

            Button {
                deckSkipAction(card: card)
            } label: {
                Text("Skip")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 24)
            .padding(.top, 8)
        }
        .padding(.top, 12)
    }

    @ViewBuilder
    private func deckAuthorAvatar(card: HelpCard) -> some View {
        Group {
            if let pic = card.authorProfilePic, !pic.isEmpty {
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

    private var allCaughtUpState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.green)
            Text("You're all caught up!")
                .font(.title3)
                .fontWeight(.medium)
            Text("You've seen all the cards.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Button("Start over") {
                deckCurrentIndex = 0
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .padding(.top, 8)
            Spacer()
        }
    }

    private func deckHelpAction(card: HelpCard) {
        Task {
            do {
                try await helpCardService.swipeRight(cardId: card.id)
            } catch {
                #if DEBUG
                print("[CircleFeedView] swipeRight error: \(error)")
                #endif
            }
        }
        withAnimation(.easeInOut(duration: 0.25)) {
            deckCurrentIndex += 1
        }
    }

    private func deckSkipAction(card: HelpCard) {
        Task {
            do {
                try await helpCardService.swipeLeft(cardId: card.id)
            } catch {
                #if DEBUG
                print("[CircleFeedView] swipeLeft error: \(error)")
                #endif
            }
        }
        withAnimation(.easeInOut(duration: 0.25)) {
            deckCurrentIndex += 1
        }
    }

    private func deckGoBack() {
        guard deckCurrentIndex > 0 else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            deckCurrentIndex -= 1
        }
    }

    private var emptyDeckState: some View {
        VStack(spacing: 12) {
            Image(systemName: "rectangle.stack")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("No help cards in this circle yet.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Post a help card if you need assistance!")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    private func loadDeckCards() async {
        isDeckLoading = true
        do {
            deckCards = try await helpCardService.fetchCircleCards(circleId: circle.id)
            deckCurrentIndex = 0
        } catch {
            #if DEBUG
            print("[CircleFeedView] loadDeckCards error: \(error)")
            #endif
        }
        isDeckLoading = false
    }
}
