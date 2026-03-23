//
//  ExploreView.swift
//  Helpdecks
//
//  Explore page: posts from all circles in the same card layout as the main feed.
//

import SwiftUI

struct ExploreView: View {
    @EnvironmentObject var feedViewModel: FeedViewModel
    @StateObject private var circleService = CircleService()
    @State private var promotedCircles: [Circle] = []
    @State private var myCircles: [Circle] = []
    @State private var discoverCircles: [Circle] = []
    @State private var showAllGroups = false
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar + All groups button (no bell icon)
                HStack(spacing: 12) {
                    HStack(spacing: 10) {
                        Image("SearchIcon", bundle: .module)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .foregroundColor(Color(.systemGray))

                        TextField("Search", text: $searchText)
                            .font(.system(size: 16))
                            .autocorrectionDisabled()
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    Button {
                        showAllGroups = true
                    } label: {
                        Text("All groups")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                // Same help post cards as the main feed
                ScrollView {
                    if feedViewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                    } else if feedViewModel.posts.isEmpty {
                        emptyState
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(explorePosts.enumerated()), id: \.element.id) { index, post in
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
                                    if index < explorePosts.count - 1 {
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
            }
            .background(Color(.systemBackground))
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable { await loadAll() }
            .task { await loadAll() }
            .sheet(isPresented: $showAllGroups) {
                AllGroupsSheet(
                    promotedCircles: promotedCircles,
                    myCircles: myCircles,
                    discoverCircles: discoverCircles
                )
            }
        }
    }

    private var explorePosts: [Post] {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            return feedViewModel.posts
        }
        let query = searchText.lowercased()
        return feedViewModel.posts.filter {
            $0.title.lowercased().contains(query) ||
            $0.body.lowercased().contains(query) ||
            $0.circleName.lowercased().contains(query) ||
            $0.authorName.lowercased().contains(query)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("No posts to explore yet")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Posts from all circles will appear here")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    private func loadAll() async {
        await feedViewModel.loadExploreFeed()
        do {
            promotedCircles = try await circleService.fetchPromotedCircles()
            myCircles = try await circleService.fetchMyCircles()
            let allPublic = try await circleService.fetchPublicCircles()
            let myIds = Set(myCircles.map(\.id))
            let promotedIds = Set(promotedCircles.map(\.id))
            discoverCircles = allPublic.filter { !myIds.contains($0.id) && !promotedIds.contains($0.id) }
        } catch {
            #if DEBUG
            print("[ExploreView] loadAll error: \(error)")
            #endif
        }
    }
}

// MARK: - All Groups Sheet
struct AllGroupsSheet: View {
    let promotedCircles: [Circle]
    let myCircles: [Circle]
    let discoverCircles: [Circle]
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss

    private var filteredPromoted: [Circle] { filterCircles(promotedCircles) }
    private var filteredMy: [Circle] { filterCircles(myCircles) }
    private var filteredDiscover: [Circle] { filterCircles(discoverCircles) }

    private func filterCircles(_ circles: [Circle]) -> [Circle] {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else { return circles }
        let query = searchText.lowercased()
        return circles.filter {
            $0.name.lowercased().contains(query) ||
            $0.category.lowercased().contains(query) ||
            $0.circleDescription.lowercased().contains(query)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Image("SearchIcon", bundle: .module)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundColor(Color(.systemGray))

                    TextField("Search groups", text: $searchText)
                        .font(.system(size: 16))
                        .autocorrectionDisabled()
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.vertical, 12)

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if !filteredPromoted.isEmpty {
                            sectionHeader("Promoted")
                            LazyVStack(spacing: 10) {
                                ForEach(filteredPromoted, id: \.id) { circle in
                                    NavigationLink(destination: CircleFeedView(circle: circle)) {
                                        CircleRowView(circle: circle, isPromoted: true)
                                    }
                                    .buttonStyle(.plain)
                                    .simultaneousGesture(TapGesture().onEnded { dismiss() })
                                }
                            }
                        }

                        if !filteredMy.isEmpty {
                            sectionHeader("My Circles")
                            LazyVStack(spacing: 10) {
                                ForEach(filteredMy, id: \.id) { circle in
                                    NavigationLink(destination: CircleFeedView(circle: circle)) {
                                        CircleRowView(circle: circle, isPromoted: false)
                                    }
                                    .buttonStyle(.plain)
                                    .simultaneousGesture(TapGesture().onEnded { dismiss() })
                                }
                            }
                        }

                        if !filteredDiscover.isEmpty {
                            sectionHeader("Discover")
                            LazyVStack(spacing: 10) {
                                ForEach(filteredDiscover, id: \.id) { circle in
                                    NavigationLink(destination: CircleFeedView(circle: circle)) {
                                        CircleRowView(circle: circle, isPromoted: false)
                                    }
                                    .buttonStyle(.plain)
                                    .simultaneousGesture(TapGesture().onEnded { dismiss() })
                                }
                            }
                        }

                        if !searchText.isEmpty && filteredPromoted.isEmpty && filteredMy.isEmpty && filteredDiscover.isEmpty {
                            VStack(spacing: 12) {
                                Image("SearchIcon", bundle: .module)
                                    .renderingMode(.template)
                                    .scaledToFit()
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(.secondary)
                                Text("No groups match \"\(searchText)\"")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("All Groups")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.title3)
            .fontWeight(.bold)
            .padding(.horizontal, 4)
    }
}
