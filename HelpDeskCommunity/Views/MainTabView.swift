//
//  MainTabView.swift
//  Helpdecks
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var feedViewModel: FeedViewModel
    @State private var selectedTab = 0
    @State private var showCreatePostFullScreen = false
    @State private var showChats = false

    var body: some View {
        mainContent
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom) {
                ModularTabBar(selectedTab: $selectedTab, onCreateTap: {
                    showCreatePostFullScreen = true
                })
            }
            .fullScreenCover(isPresented: $showCreatePostFullScreen) {
                CreatePostFullPageView()
                    .environmentObject(feedViewModel)
                    .environmentObject(authViewModel)
            }
            .sheet(isPresented: $showChats) {
                ChatsView()
            }
    }

    @ViewBuilder
    private var mainContent: some View {
        switch selectedTab {
        case 0: HomeView(showChats: $showChats)
        case 1: ExploreView()
        case 2: EmptyView()
        case 3: HelpDeckSwipeView()
        case 4: ProfileView(showChats: $showChats)
        default: HomeView(showChats: $showChats)
        }
    }
}

// MARK: - Modular Tab Bar (extracted to fix compiler type-check)

struct ModularTabBar: View {
    @Binding var selectedTab: Int
    var onCreateTap: (() -> Void)? = nil

    private let tabs: [(icon: String, tag: Int, isCreate: Bool)] = [
        ("HomeIcon", 0, false),
        ("SearchIcon", 1, false),
        ("", 2, true),
        ("CardsIcon", 3, false),
        ("ProfileIcon", 4, false),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.tag) { tab in
                if tab.isCreate {
                    createTabButton
                } else {
                    tabButton(tab: (icon: tab.icon, tag: tab.tag))
                }
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

    private var createTabButton: some View {
        Button {
            onCreateTap?()
        } label: {
            ZStack {
                SwiftUI.Circle()
                    .fill(Color.blue)
                    .frame(width: 46, height: 46)
                Image(systemName: "megaphone.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Create post")
    }

    private func tabButton(tab: (icon: String, tag: Int)) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab.tag
            }
        } label: {
            Image(tab.icon, bundle: .module)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundColor(selectedTab == tab.tag ? .blue : Color(.systemGray))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Home Tab

struct HomeView: View {
    @Binding var showChats: Bool
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
            .background(Color(.systemBackground))
            .refreshable { await loadFeed() }
            .navigationTitle("Helpdesk")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { showChats = true } label: {
                        Image("MessageIcon", bundle: .module)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                            .foregroundColor(.primary)
                    }
                    Button { /* Notifications - next iteration */ } label: {
                        Image("BellIcon", bundle: .module)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
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
                            Image("BellIcon", bundle: .module)
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22, height: 22)
                                .foregroundColor(.primary)
                        }
                    }
                }
        }
    }
}

// MARK: - Profile Tab

struct ProfileView: View {
    @Binding var showChats: Bool
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
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { showChats = true } label: {
                        Image("MessageIcon", bundle: .module)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                            .foregroundColor(.primary)
                    }
                    Button { /* Notifications - next iteration */ } label: {
                        Image("BellIcon", bundle: .module)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
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
