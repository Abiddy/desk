//
//  DecksListView.swift
//  HelpDeskCommunity
//

import SwiftUI
import CoreLocation

struct DecksListView: View {
    @StateObject private var helpCardService = HelpCardService()
    @StateObject private var deckService = DeckService()
    @EnvironmentObject var locationService: LocationService

    @State private var urgentCount = 0
    @State private var nearbyCount = 0
    @State private var skillsCount = 0
    @State private var communityDecks: [Deck] = []
    @State private var deckCardCounts: [String: Int] = [:]
    @State private var showCreateCard = false
    @State private var showCreateDeck = false
    @State private var showJoinDeck = false
    @State private var distanceRadius: Double = 25

    @AppStorage("userSkills") private var userSkillsData: Data = Data()

    private var userSkills: [String] {
        (try? JSONDecoder().decode([String].self, from: userSkillsData)) ?? []
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // System decks
                    VStack(spacing: 12) {
                        NavigationLink {
                            DeckSwipeView(
                                mode: .urgent,
                                helpCardService: helpCardService
                            )
                        } label: {
                            DeckRowView(
                                icon: "flame.fill",
                                iconColor: .red,
                                title: "Urgent Today",
                                subtitle: "Time-sensitive requests",
                                count: urgentCount
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            DeckSwipeView(
                                mode: .nearby(radius: distanceRadius, location: locationService.currentLocation),
                                helpCardService: helpCardService
                            )
                        } label: {
                            VStack(spacing: 8) {
                                DeckRowView(
                                    icon: "location.fill",
                                    iconColor: .blue,
                                    title: "Near You",
                                    subtitle: "\(Int(distanceRadius)) mi radius",
                                    count: nearbyCount
                                )
                            }
                        }
                        .buttonStyle(.plain)

                        // Distance slider
                        HStack {
                            Image(systemName: "location.circle")
                                .foregroundColor(.secondary)
                                .font(.caption)
                            Slider(value: $distanceRadius, in: 1...100, step: 1)
                                .tint(.blue)
                                .onChange(of: distanceRadius) {
                                    Task { await refreshCounts() }
                                }
                            Text("\(Int(distanceRadius)) mi")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 45, alignment: .trailing)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 4)

                        if !userSkills.isEmpty {
                            NavigationLink {
                                DeckSwipeView(
                                    mode: .skills(userSkills),
                                    helpCardService: helpCardService
                                )
                            } label: {
                                DeckRowView(
                                    icon: "sparkles",
                                    iconColor: .orange,
                                    title: "Your Skills",
                                    subtitle: userSkills.prefix(3).joined(separator: ", "),
                                    count: skillsCount
                                )
                            }
                            .buttonStyle(.plain)
                        } else {
                            NavigationLink {
                                SkillSelectionView()
                            } label: {
                                DeckRowView(
                                    icon: "sparkles",
                                    iconColor: .orange,
                                    title: "Your Skills",
                                    subtitle: "Tap to select your skills",
                                    count: nil
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 8)

                    // Community decks
                    if !communityDecks.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("My Communities")
                                .font(.headline)
                                .padding(.horizontal, 20)

                            ForEach(communityDecks, id: \.id) { deck in
                                NavigationLink {
                                    DeckSwipeView(
                                        mode: .deck(deck.id),
                                        helpCardService: helpCardService
                                    )
                                } label: {
                                    DeckRowView(
                                        icon: deck.iconName,
                                        iconColor: .purple,
                                        title: deck.name,
                                        subtitle: "\(deck.memberIds.count) members",
                                        count: deckCardCounts[deck.id]
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Join / Create deck buttons
                    VStack(spacing: 10) {
                        Button { showCreateDeck = true } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Create a Deck")
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.purple.opacity(0.15))
                            .foregroundColor(.purple)
                            .cornerRadius(12)
                        }

                        Button { showJoinDeck = true } label: {
                            HStack {
                                Image(systemName: "ticket.fill")
                                Text("Join with Invite Code")
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray5))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
                .padding(.bottom, 20)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Decks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showCreateCard = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.purple)
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showCreateCard) {
                CreateHelpCardView(helpCardService: helpCardService)
            }
            .sheet(isPresented: $showCreateDeck) {
                CreateDeckView(deckService: deckService) { newDeck in
                    communityDecks.append(newDeck)
                }
            }
            .sheet(isPresented: $showJoinDeck) {
                JoinDeckView(deckService: deckService) { joinedDeck in
                    if !communityDecks.contains(where: { $0.id == joinedDeck.id }) {
                        communityDecks.append(joinedDeck)
                    }
                }
            }
            .task { await refreshAll() }
        }
    }

    private func refreshAll() async {
        await refreshCounts()
        do {
            communityDecks = try await deckService.fetchMyDecks()
            for deck in communityDecks {
                deckCardCounts[deck.id] = try await deckService.cardCount(deckId: deck.id)
            }
        } catch {
            #if DEBUG
            print("[DecksListView] fetchMyDecks error: \(error)")
            #endif
        }
    }

    private func refreshCounts() async {
        do {
            let urgent = try await helpCardService.fetchUrgentCards()
            urgentCount = urgent.count

            if let loc = locationService.currentLocation {
                let nearby = try await helpCardService.fetchNearbyCards(
                    userLocation: loc, radiusMiles: distanceRadius
                )
                nearbyCount = nearby.count
            }

            if !userSkills.isEmpty {
                let skillCards = try await helpCardService.fetchSkillCards(skills: userSkills)
                skillsCount = skillCards.count
            }
        } catch {
            #if DEBUG
            print("[DecksListView] refreshCounts error: \(error)")
            #endif
        }
    }
}

// MARK: - Deck row

struct DeckRowView: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let count: Int?

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 44, height: 44)
                .background(iconColor.opacity(0.15))
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if let count {
                Text("\(count)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(count > 0 ? iconColor : Color.gray)
                    .cornerRadius(12)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}
