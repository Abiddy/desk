//
//  HelpDeskCommunityApp.swift
//  HelpDeskCommunity
//
//  Created on Feb 12, 2026.
//

import SwiftUI
import SwiftData

@main
struct HelpDeskCommunityApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var locationService = LocationService()
    @StateObject private var joinedGroupsStore = JoinedGroupsStore()
    @StateObject private var feedViewModel = FeedViewModel()
    @StateObject private var followService = FollowService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(locationService)
                .environmentObject(joinedGroupsStore)
                .environmentObject(feedViewModel)
                .environmentObject(followService)
                .modelContainer(for: [User.self, Group.self, Message.self, Post.self, Comment.self])
                .task {
                    await followService.loadFollowing()
                    await joinedGroupsStore.loadFromFirestore()
                }
        }
    }
}
