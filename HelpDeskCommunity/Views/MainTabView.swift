//
//  MainTabView.swift
//  Helpdecks
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)

            CirclesListView()
                .tabItem { Label("Circles", systemImage: "circle.grid.3x3.fill") }
                .tag(1)

            ChatsView()
                .tabItem { Label("Chats", systemImage: "message.fill") }
                .tag(2)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
                .tag(3)
        }
        .tint(.purple)
    }
}

// MARK: - Home Tab

struct HomeView: View {
    @EnvironmentObject var joinedCirclesStore: JoinedCirclesStore
    @EnvironmentObject var feedViewModel: FeedViewModel
    @EnvironmentObject var followService: FollowService
    @State private var showCreatePost = false

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
            .background(Color(.systemGroupedBackground))
            .refreshable { await loadFeed() }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showCreatePost = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.purple)
                    }
                }
            }
            .sheet(isPresented: $showCreatePost) {
                CreatePostView()
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
                .navigationTitle("Chats")
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
                            .foregroundColor(.purple)

                        Text(authViewModel.authService.currentUser?.name ?? "User")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text(authViewModel.authService.currentUser?.email ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        if let location = locationService.locationString ?? authViewModel.authService.currentUser?.location {
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.purple)
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
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profile")
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
                .foregroundColor(.purple)
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
