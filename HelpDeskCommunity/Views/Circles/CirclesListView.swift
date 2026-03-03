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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                    } else {
                        // Promoted circles
                        if !promotedCircles.isEmpty {
                            sectionHeader("Promoted")
                            LazyVStack(spacing: 10) {
                                ForEach(promotedCircles, id: \.id) { circle in
                                    NavigationLink(destination: CircleFeedView(circle: circle)) {
                                        CircleRowView(circle: circle, isPromoted: true)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }

                        // My circles
                        if !myCircles.isEmpty {
                            sectionHeader("My Circles")
                            LazyVStack(spacing: 10) {
                                ForEach(myCircles, id: \.id) { circle in
                                    NavigationLink(destination: CircleFeedView(circle: circle)) {
                                        CircleRowView(circle: circle, isPromoted: false)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }

                        // Discover
                        if !discoverCircles.isEmpty {
                            sectionHeader("Discover")
                            LazyVStack(spacing: 10) {
                                ForEach(discoverCircles, id: \.id) { circle in
                                    NavigationLink(destination: CircleFeedView(circle: circle)) {
                                        CircleRowView(circle: circle, isPromoted: false)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }

                        // Actions
                        VStack(spacing: 12) {
                            Button { showCreateCircle = true } label: {
                                Label("Create a Circle", systemImage: "plus.circle.fill")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.purple)
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
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Circles")
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
        case "business": return .purple
        default: return .gray
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: circle.iconName)
                .font(.title2)
                .foregroundColor(isPromoted ? categoryColor : .purple)
                .frame(width: 48, height: 48)
                .background(isPromoted ? categoryColor.opacity(0.12) : Color.purple.opacity(0.12))
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
