//
//  MainTabView.swift
//  HelpDeskCommunity
//
//  Created on Feb 12, 2026.
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
            
            DecksListView()
                .tabItem { Label("Decks", systemImage: "rectangle.stack.fill") }
                .tag(1)
            
            ChatsView()
                .tabItem { Label("Chats", systemImage: "message.fill") }
                .tag(2)
            
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
                .tag(3)
        }
        .tint(.white)
        .preferredColorScheme(.dark)
    }
}

// Home tab – group chips, feed cards, gear, create post
struct HomeView: View {
    @EnvironmentObject var joinedGroupsStore: JoinedGroupsStore
    @EnvironmentObject var feedViewModel: FeedViewModel
    @EnvironmentObject var followService: FollowService
    @State private var showCreatePost = false
    @State private var navigateToGroup: String? = nil

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                // Feed
                ScrollView {
                    let displayPosts = feedViewModel.posts

                    if feedViewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                    } else if displayPosts.isEmpty {
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
                            ForEach(displayPosts, id: \.id) { post in
                                NavigationLink(destination: PostDetailView(post: post)) {
                                    PostCardView(
                                        post: post,
                                        onLike: { Task { await feedViewModel.toggleLike(postId: post.id) } },
                                        onComment: {},
                                        onShare: { Task { await feedViewModel.incrementShare(postId: post.id) } },
                                        onGroupTap: { navigateToGroup = post.groupCategory },
                                        onAuthorTap: nil
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }
                }
                .refreshable {
                    await loadFeed()
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { showCreatePost = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.purple)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: GroupSelectionSettingsView()) {
                        HStack(spacing: 4) {
                            Text("Groups")
                                .fontWeight(.medium)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                        .foregroundColor(.purple)
                    }
                }
            }
            .sheet(isPresented: $showCreatePost) {
                CreatePostView()
            }
            .navigationDestination(item: $navigateToGroup) { category in
                GroupFeedView(groupCategory: category)
            }
            .task { await loadFeed() }
        }
    }

    private func loadFeed() async {
        let joined = Array(joinedGroupsStore.joinedGroupIds)
        let following = Array(followService.followingUserIds)
        await feedViewModel.loadFeed(joinedGroupIds: joined, followingUserIds: following)
    }
}

// Settings: select which groups you're in
struct GroupSelectionSettingsView: View {
    @EnvironmentObject var joinedGroupsStore: JoinedGroupsStore
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            Section {
                Text("Choose the groups you want to see in your Home feed.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Section("Groups") {
                ForEach(GroupCategory.allCases, id: \.rawValue) { category in
                    Toggle(category.rawValue, isOn: Binding(
                        get: { joinedGroupsStore.isJoined(category.rawValue) },
                        set: { joinedGroupsStore.setJoined(category.rawValue, $0) }
                    ))
                }
            }
        }
        .navigationTitle("Group Selection")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Explore tab – browse / search later
struct ExploreView: View {
    var body: some View {
        NavigationStack {
            Text("Explore – Coming Soon")
                .navigationTitle("Explore")
        }
    }
}

struct ChatsView: View {
    var body: some View {
        NavigationView {
            Text("Chats View - Coming Soon")
                .navigationTitle("Chats")
        }
    }
}

struct UsersView: View {
    var body: some View {
        NavigationView {
            Text("Users View - Coming Soon")
                .navigationTitle("Users")
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var locationService: LocationService
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
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
                    
                    // Settings Section
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
                    
                    // Other Options
                    VStack(alignment: .leading, spacing: 16) {
                        Text("More")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        NavigationLink(destination: LocalAdsView()) {
                            SettingsRow(icon: "megaphone", title: "Local Ads")
                        }
                        
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
                        
                        NavigationLink(destination: SupportHelpDeskView()) {
                            SettingsRow(icon: "questionmark.circle", title: "Support HelpDesk")
                        }
                        
                        NavigationLink(destination: AppHelpView()) {
                            SettingsRow(icon: "book", title: "App Help/Guide")
                        }
                    }
                    
                    // Sign Out
                    Button(action: {
                        authViewModel.signOut()
                    }) {
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
            .navigationTitle("Profile")
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(title)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.caption)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

// Placeholder views for settings
struct ProfileSettingsView: View {
    var body: some View {
        Text("Profile Settings - Coming Soon")
            .navigationTitle("Edit Profile")
    }
}

struct ChatSettingsView: View {
    var body: some View {
        Text("Chat Settings - Coming Soon")
            .navigationTitle("Chat Settings")
    }
}

struct NotificationSettingsView: View {
    var body: some View {
        Text("Notification Settings - Coming Soon")
            .navigationTitle("Notifications")
    }
}

struct BlockedUsersView: View {
    var body: some View {
        Text("Blocked Users - Coming Soon")
            .navigationTitle("Blocked Users")
    }
}

struct LocalAdsView: View {
    var body: some View {
        Text("Local Ads - Coming Soon")
            .navigationTitle("Local Ads")
    }
}

struct ShareAppView: View {
    var body: some View {
        Text("Share App - Coming Soon")
            .navigationTitle("Share App")
    }
}

struct FeedbackView: View {
    var body: some View {
        Text("Feedback - Coming Soon")
            .navigationTitle("Feedback")
    }
}

struct ContactUsView: View {
    var body: some View {
        Text("Contact Us - Coming Soon")
            .navigationTitle("Contact Us")
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        Text("Privacy Policy - Coming Soon")
            .navigationTitle("Privacy Policy")
    }
}

struct SupportHelpDeskView: View {
    var body: some View {
        Text("Support HelpDesk - Coming Soon")
            .navigationTitle("Support HelpDesk")
    }
}

struct AppHelpView: View {
    var body: some View {
        Text("App Help/Guide - Coming Soon")
            .navigationTitle("App Help")
    }
}
