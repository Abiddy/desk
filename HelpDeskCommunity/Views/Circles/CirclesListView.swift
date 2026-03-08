//
//  CirclesListView.swift
//  Helpdecks
//

import SwiftUI

struct CirclesListView: View {
    @StateObject private var circleService = CircleService()
    @State private var promotedCircles: [Circle] = []
    @State private var myCircles: [Circle] = []
    @State private var discoverCircles: [Circle] = []
    @State private var showCreateCircle = false
    @State private var showJoinCircle = false
    @State private var isLoading = true
    @State private var searchText = ""

    private var filteredPromoted: [Circle] {
        filterCircles(promotedCircles)
    }
    private var filteredMyCircles: [Circle] {
        filterCircles(myCircles)
    }
    private var filteredDiscover: [Circle] {
        filterCircles(discoverCircles)
    }

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
                // Custom search bar - rounded, transparent, custom icon
                HStack(spacing: 10) {
                    Image("SearchIcon", bundle: .module)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundColor(Color(.systemGray))

                    TextField("Search circles", text: $searchText)
                        .font(.system(size: 16))
                        .autocorrectionDisabled()
                }
                .padding(12)
                .background(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                    } else {
                        // Promoted circles
                        if !filteredPromoted.isEmpty {
                            sectionHeader("Promoted")
                            LazyVStack(spacing: 10) {
                                ForEach(filteredPromoted, id: \.id) { circle in
                                    NavigationLink(destination: CircleFeedView(circle: circle)) {
                                        CircleRowView(circle: circle, isPromoted: true)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }

                        // My circles
                        if !filteredMyCircles.isEmpty {
                            sectionHeader("My Circles")
                            LazyVStack(spacing: 10) {
                                ForEach(filteredMyCircles, id: \.id) { circle in
                                    NavigationLink(destination: CircleFeedView(circle: circle)) {
                                        CircleRowView(circle: circle, isPromoted: false)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }

                        // Discover
                        if !filteredDiscover.isEmpty {
                            sectionHeader("Discover")
                            LazyVStack(spacing: 10) {
                                ForEach(filteredDiscover, id: \.id) { circle in
                                    NavigationLink(destination: CircleFeedView(circle: circle)) {
                                        CircleRowView(circle: circle, isPromoted: false)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }

                        // No results
                        if !searchText.isEmpty && filteredPromoted.isEmpty && filteredMyCircles.isEmpty && filteredDiscover.isEmpty {
                            VStack(spacing: 12) {
                                Image("SearchIcon", bundle: .module)
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(.secondary)
                                Text("No circles match \"\(searchText)\"")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                        }

                        // Actions
                        VStack(spacing: 12) {
                            Button { showCreateCircle = true } label: {
                                Label("Create a Circle", systemImage: "plus.circle.fill")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }

                            Button { showJoinCircle = true } label: {
                                Label("Join with Invite Code", systemImage: "ticket.fill")
                                    .fontWeight(.medium)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color(.systemGray6))
                                    .foregroundColor(.primary)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemBackground))
            }
            .background(Color(.systemBackground))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
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
            .refreshable { await loadAll() }
            .task { await loadAll() }
            .sheet(isPresented: $showCreateCircle) {
                CreateCircleView(circleService: circleService, onCreated: { await loadAll() })
            }
            .sheet(isPresented: $showJoinCircle) {
                JoinCircleView(circleService: circleService, onJoined: { await loadAll() })
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.title3)
            .fontWeight(.bold)
            .padding(.horizontal)
    }

    private func loadAll() async {
        isLoading = true
        do {
            promotedCircles = try await circleService.fetchPromotedCircles()
            myCircles = try await circleService.fetchMyCircles()
            let allPublic = try await circleService.fetchPublicCircles()
            let myIds = Set(myCircles.map(\.id))
            let promotedIds = Set(promotedCircles.map(\.id))
            discoverCircles = allPublic.filter { !myIds.contains($0.id) && !promotedIds.contains($0.id) }
        } catch {
            #if DEBUG
            print("[CirclesListView] loadAll error: \(error)")
            #endif
        }
        isLoading = false
    }
}

struct CircleRowView: View {
    let circle: Circle
    let isPromoted: Bool

    private var categoryColor: Color {
        switch circle.category.lowercased() {
        case "tech": return .blue
        case "medical": return .red
        case "legal": return .orange
        case "business": return .indigo
        default: return .gray
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: circle.iconName)
                .font(.title2)
                .foregroundColor(isPromoted ? categoryColor : .blue)
                .frame(width: 48, height: 48)
                .background(isPromoted ? categoryColor.opacity(0.12) : Color.blue.opacity(0.12))
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 3) {
                Text(circle.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Text(formattedFollowers(circle.followerCount))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(12)
    }

    private func formattedFollowers(_ count: Int) -> String {
        if count >= 1000 {
            return String(format: "%.1fK followers", Double(count) / 1000.0)
        }
        return "\(count) followers"
    }
}
