//
//  MainTabView.swift
//  Helpdecks
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab = 0

    var body: some View {
        mainContent
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom) {
                ModularTabBar(selectedTab: $selectedTab)
            }
    }

    @ViewBuilder
    private var mainContent: some View {
        switch selectedTab {
        case 0: HomeView()
        case 1: CirclesListView()
        case 2: ChatsView()
        case 3: ProfileView()
        default: HomeView()
        }
    }
}

// MARK: - Modular Tab Bar (extracted to fix compiler type-check)

struct ModularTabBar: View {
    @Binding var selectedTab: Int

    private let tabs: [(icon: String, tag: Int)] = [
        ("house.fill", 0),
        ("square.grid.2x2.fill", 1),
        ("bubble.left.and.bubble.right.fill", 2),
        ("person.crop.circle.fill", 3)
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.tag) { tab in
                tabButton(tab: tab)
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color(.separator).opacity(0.3))
                .frame(height: 0.5)
        }
    }

    private func tabButton(tab: (icon: String, tag: Int)) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab.tag
            }
        } label: {
            ZStack {
                SwiftUI.Circle()
                    .fill(selectedTab == tab.tag ? Color.blue : Color(.systemGray5))
                    .frame(width: 36, height: 36)
                Image(systemName: tab.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(selectedTab == tab.tag ? .white : Color(.systemGray))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Home Tab

struct HomeView: View {
    @EnvironmentObject var joinedCirclesStore: JoinedCirclesStore
    @EnvironmentObject var feedViewModel: FeedViewModel
    @EnvironmentObject var followService: FollowService

    var body: some View {
        NavigationStack {
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
                        Text("No posts yet. Be the first to post!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(feedViewModel.posts.enumerated()), id: \.element.id) { index, post in
                            VStack(spacing: 0) {
                                NavigationLink(destination: PostDetailView(post: post)) {
                                    PostCardView(
                                        post: post,
                                        onLike: { Task { await feedViewModel.toggleLike(postId: post.id) } },
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
            .background(Color(.systemBackground))
            .refreshable { await loadFeed() }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { /* Notifications - next iteration */ } label: {
                        Image(systemName: "bell")
                            .foregroundColor(.primary)
                    }
                }
            }
            .task { await loadFeed() }
        }
    }

    private func loadFeed() async {
        let joined = Array(joinedCirclesStore.joinedCircleIds)
        let following = Array(followService.followingUserIds)
        await feedViewModel.loadFeed(joinedCircleIds: joined, followingUserIds: following)
    }
}

// MARK: - Chats Tab

struct ChatsView: View {
    var body: some View {
        NavigationStack {
            Text("Chats - Coming Soon")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
                .navigationTitle("Chats")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { /* Notifications - next iteration */ } label: {
                            Image(systemName: "bell")
                                .foregroundColor(.primary)
                        }
                    }
                }
        }
    }
}

// MARK: - Profile Tab

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var locationService: LocationService
    @State private var isSeedingData = false
    @State private var seedStatusMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 100))
                            .foregroundColor(.blue)

                        Text(authViewModel.authService.currentUser?.name ?? "User")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text(authViewModel.authService.currentUser?.email ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        if let location = locationService.locationString ?? authViewModel.authService.currentUser?.location {
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.blue)
                                Text(location)
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding()

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Settings")
                            .font(.headline)
                            .padding(.horizontal)

                        NavigationLink(destination: ProfileSettingsView()) {
                            SettingsRow(icon: "person.circle", title: "Edit Profile")
                        }
                        NavigationLink(destination: ChatSettingsView()) {
                            SettingsRow(icon: "message.circle", title: "Chat Settings")
                        }
                        NavigationLink(destination: NotificationSettingsView()) {
                            SettingsRow(icon: "bell.circle", title: "Notifications")
                        }
                        NavigationLink(destination: BlockedUsersView()) {
                            SettingsRow(icon: "person.crop.circle.badge.xmark", title: "Blocked Users")
                        }
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        Text("More")
                            .font(.headline)
                            .padding(.horizontal)

                        NavigationLink(destination: ShareAppView()) {
                            SettingsRow(icon: "square.and.arrow.up", title: "Share App")
                        }
                        NavigationLink(destination: FeedbackView()) {
                            SettingsRow(icon: "text.bubble", title: "Feedback")
                        }
                        NavigationLink(destination: ContactUsView()) {
                            SettingsRow(icon: "envelope", title: "Contact Us")
                        }
                        NavigationLink(destination: PrivacyPolicyView()) {
                            SettingsRow(icon: "lock.shield", title: "Privacy Policy")
                        }
                        NavigationLink(destination: AppHelpView()) {
                            SettingsRow(icon: "book", title: "App Help/Guide")
                        }
                    }

                    #if DEBUG
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Developer")
                            .font(.headline)
                            .padding(.horizontal)

                        Button {
                            Task {
                                isSeedingData = true
                                seedStatusMessage = nil
                                do {
                                    try await SeedDataService().seedAll()
                                    seedStatusMessage = "Done! Circles, users, posts, and help cards seeded."
                                } catch {
                                    seedStatusMessage = "Error: \(error.localizedDescription)"
                                }
                                isSeedingData = false
                            }
                        } label: {
                            HStack {
                                if isSeedingData {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: "wand.and.stars")
                                }
                                Text(isSeedingData ? "Seeding..." : "Seed Test Data")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(isSeedingData)
                        .padding(.horizontal)

                        if let msg = seedStatusMessage {
                            Text(msg)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }
                    }
                    #endif

                    Button {
                        authViewModel.signOut()
                    } label: {
                        Text("Sign Out")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                }
                .padding(.vertical)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { /* Notifications - next iteration */ } label: {
                        Image(systemName: "bell")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
}

// MARK: - Reusable components

struct SettingsRow: View {
    let icon: String
    let title: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(title)
                .foregroundColor(.primary)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.caption)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

// MARK: - Placeholder settings views

struct ProfileSettingsView: View {
    var body: some View { Text("Edit Profile - Coming Soon").navigationTitle("Edit Profile") }
}
struct ChatSettingsView: View {
    var body: some View { Text("Chat Settings - Coming Soon").navigationTitle("Chat Settings") }
}
struct NotificationSettingsView: View {
    var body: some View { Text("Notifications - Coming Soon").navigationTitle("Notifications") }
}
struct BlockedUsersView: View {
    var body: some View { Text("Blocked Users - Coming Soon").navigationTitle("Blocked Users") }
}
struct ShareAppView: View {
    var body: some View { Text("Share App - Coming Soon").navigationTitle("Share App") }
}
struct FeedbackView: View {
    var body: some View { Text("Feedback - Coming Soon").navigationTitle("Feedback") }
}
struct ContactUsView: View {
    var body: some View { Text("Contact Us - Coming Soon").navigationTitle("Contact Us") }
}
struct PrivacyPolicyView: View {
    var body: some View { Text("Privacy Policy - Coming Soon").navigationTitle("Privacy Policy") }
}
struct AppHelpView: View {
    var body: some View { Text("App Help - Coming Soon").navigationTitle("App Help") }
}
