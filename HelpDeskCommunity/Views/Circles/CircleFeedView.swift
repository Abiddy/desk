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
    @State private var selectedTab = 0
    @State private var showCreatePost = false
    @State private var showCreateCard = false
    @State private var deckCards: [HelpCard] = []
    @State private var isDeckLoading = true

    private var isJoined: Bool {
        joinedCirclesStore.isJoined(circle.name)
    }

    var body: some View {
        VStack(spacing: 0) {
            circleHeader
                .padding(.bottom, 8)

            // Segmented picker
            Picker("", selection: $selectedTab) {
                Text("Feed").tag(0)
                Text("Decks").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 8)

            // Tab content
            if selectedTab == 0 {
                feedTab
            } else {
                decksTab
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { showCreateCard = true } label: {
                    Image(systemName: "hand.thumbsup.fill")
                        .foregroundColor(.green)
                }
            }
        }
        .sheet(isPresented: $showCreatePost) {
            CreatePostView(preselectedCircle: CircleCategory(rawValue: circle.name))
        }
        .sheet(isPresented: $showCreateCard) {
            CreateHelpCardView(helpCardService: helpCardService, circleId: circle.id)
        }
        .task {
            await feedViewModel.loadCircleFeed(circleName: circle.name)
            await loadDeckCards()
        }
    }

    // MARK: - Circle Header

    private var circleHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: circle.iconName)
                        .font(.title3)
                        .foregroundColor(.purple)
                    Text(circle.name)
                        .font(.title3)
                        .fontWeight(.bold)
                }
                Text("\(circle.followerCount) followers")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                joinedCirclesStore.toggle(circle.name)
            } label: {
                Text(isJoined ? "Joined" : "Join")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(isJoined ? Color(.systemGray5) : Color.purple)
                    .foregroundColor(isJoined ? .primary : .white)
                    .cornerRadius(20)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
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

    // MARK: - Decks Tab

    private var decksTab: some View {
        ScrollView {
            if isDeckLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
            } else if deckCards.isEmpty {
                emptyDeckState
            } else {
                VStack(spacing: 16) {
                    // Stats bar
                    deckStatsBar

                    // Card list preview
                    LazyVStack(spacing: 12) {
                        ForEach(deckCards, id: \.id) { card in
                            DeckCardPreview(card: card)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
            }
        }
        .refreshable {
            await loadDeckCards()
        }
    }

    private var deckStatsBar: some View {
        let urgentCount = deckCards.filter { $0.urgency == HelpCardUrgency.urgent.rawValue }.count
        return HStack(spacing: 16) {
            StatPill(icon: "rectangle.stack.fill", label: "\(deckCards.count) cards", color: .purple)
            if urgentCount > 0 {
                StatPill(icon: "flame.fill", label: "\(urgentCount) urgent", color: .red)
            }
            Spacer()
        }
        .padding(.horizontal)
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
        } catch {
            #if DEBUG
            print("[CircleFeedView] loadDeckCards error: \(error)")
            #endif
        }
        isDeckLoading = false
    }
}

// MARK: - Deck card preview row

struct DeckCardPreview: View {
    let card: HelpCard

    private var skill: HelpCardSkill {
        HelpCardSkill(rawValue: card.skill) ?? .other
    }

    private var isUrgent: Bool {
        card.urgency == HelpCardUrgency.urgent.rawValue
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(skill.rawValue, systemImage: skill.icon)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.12))
                    .foregroundColor(.purple)
                    .cornerRadius(6)

                if isUrgent {
                    Label("Urgent", systemImage: "flame.fill")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.12))
                        .foregroundColor(.red)
                        .cornerRadius(6)
                }

                Spacer()

                Text(card.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Text(card.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(2)

            Text(card.cardDescription)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)

            HStack(spacing: 8) {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.gray)
                Text(card.authorName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                if let loc = card.locationName {
                    Text("· \(loc)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 3, y: 2)
    }
}

// MARK: - Stat pill

struct StatPill: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}
