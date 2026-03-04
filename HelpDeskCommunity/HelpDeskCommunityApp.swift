//
//  HelpDeskCommunityApp.swift
//  Helpdecks
//

import SwiftUI
import SwiftData

@main
struct HelpDeskCommunityApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var locationService = LocationService()
    @StateObject private var joinedCirclesStore = JoinedCirclesStore()
    @StateObject private var feedViewModel = FeedViewModel()
    @StateObject private var followService = FollowService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
                .environmentObject(authViewModel)
                .environmentObject(locationService)
                .environmentObject(joinedCirclesStore)
                .environmentObject(feedViewModel)
                .environmentObject(followService)
                .modelContainer(for: [User.self, Circle.self, Message.self, Post.self, Comment.self, HelpCard.self])
                .task {
                    await followService.loadFollowing()
                    await joinedCirclesStore.loadFromFirestore()
                }
        }
    }
}
