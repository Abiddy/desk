//
//  DeckSwipeView.swift
//  HelpDeskCommunity
//

import SwiftUI
import CoreLocation

enum DeckSwipeMode {
    case urgent
    case nearby(radius: Double, location: CLLocation?)
    case skills([String])
    case deck(String)
}

struct DeckSwipeView: View {
    let mode: DeckSwipeMode
    @ObservedObject var helpCardService: HelpCardService
    @EnvironmentObject var locationService: LocationService
    @Environment(\.dismiss) private var dismiss

    @State private var cards: [HelpCard] = []
    @State private var isLoading = true
    @State private var currentIndex = 0
    @State private var dragOffset = CGSize.zero
    @State private var swipeDirection: SwipeDirection? = nil

    private enum SwipeDirection {
        case left, right
    }

    private var currentCard: HelpCard? {
        guard currentIndex < cards.count else { return nil }
        return cards[currentIndex]
    }

    var body: some View {
        VStack {
            if isLoading {
                Spacer()
                ProgressView("Loading cards...")
                Spacer()
            } else if cards.isEmpty {
                emptyState
            } else if let card = currentCard {
                cardStack(card: card)
            } else {
                allDoneState
            }
        }
        .background(Color(.systemBackground))
        .navigationTitle(modeTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadCards() }
    }

    // MARK: - Card stack

    @ViewBuilder
    private func cardStack(card: HelpCard) -> some View {
        ZStack {
            // Next card preview (behind)
            if currentIndex + 1 < cards.count {
                helpCardView(for: cards[currentIndex + 1])
                    .scaleEffect(0.95)
                    .opacity(0.6)
                    .offset(y: 8)
            }

            // Current card (draggable)
            helpCardView(for: card)
                .offset(dragOffset)
                .rotationEffect(.degrees(Double(dragOffset.width) / 20))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation
                            if value.translation.width > 0 {
                                swipeDirection = .right
                            } else {
                                swipeDirection = .left
                            }
                        }
                        .onEnded { value in
                            let threshold: CGFloat = 120
                            if value.translation.width > threshold {
                                performSwipe(.right, card: card)
                            } else if value.translation.width < -threshold {
                                performSwipe(.left, card: card)
                            } else {
                                withAnimation(.spring(response: 0.3)) {
                                    dragOffset = .zero
                                    swipeDirection = nil
                                }
                            }
                        }
                )
                .overlay(alignment: .topLeading) {
                    swipeLabel
                }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)

        Spacer()

        // Bottom buttons
        HStack(spacing: 40) {
            Button {
                performSwipe(.left, card: card)
            } label: {
                Image(systemName: "xmark")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                    .frame(width: 64, height: 64)
                    .background(Color.red.opacity(0.15))
                    .clipShape(Circle())
            }

            Button {
                performSwipe(.right, card: card)
            } label: {
                Image(systemName: "hand.thumbsup.fill")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                    .frame(width: 64, height: 64)
                    .background(Color.green.opacity(0.15))
                    .clipShape(Circle())
            }
        }
        .padding(.bottom, 30)

        Text("\(cards.count - currentIndex) cards remaining")
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.bottom, 16)
    }

    // MARK: - Swipe label overlay

    @ViewBuilder
    private var swipeLabel: some View {
        if let dir = swipeDirection, abs(dragOffset.width) > 40 {
            Text(dir == .right ? "I CAN HELP" : "SKIP")
                .font(.title2)
                .fontWeight(.heavy)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(dir == .right ? Color.green : Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
                .rotationEffect(.degrees(dir == .right ? -15 : 15))
                .padding(20)
                .opacity(min(abs(dragOffset.width) / 120, 1.0))
        }
    }

    // MARK: - Single card view

    @ViewBuilder
    private func helpCardView(for card: HelpCard) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Skill badge + urgency
            HStack {
                let skill = HelpCardSkill(rawValue: card.skill) ?? .other
                Label(skill.rawValue, systemImage: skill.icon)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.purple.opacity(0.2))
                    .foregroundColor(.purple)
                    .cornerRadius(8)

                if card.urgency == HelpCardUrgency.urgent.rawValue {
                    Label("Urgent", systemImage: "flame.fill")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.red.opacity(0.2))
                        .foregroundColor(.red)
                        .cornerRadius(8)
                }

                Spacer()

                if card.isRemote {
                    Label("Remote", systemImage: "globe")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Title
            Text(card.title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.leading)

            // Description
            Text(card.cardDescription)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)

            Spacer()

            // Author + location
            HStack {
                if let pic = card.authorProfilePic, !pic.isEmpty {
                    AsyncImage(url: URL(string: pic)) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Image(systemName: "person.circle.fill").resizable()
                    }
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 32, height: 32)
                        .foregroundColor(.gray)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(card.authorName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    if let locName = card.locationName {
                        Text(locName)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if let userLoc = locationService.currentLocation,
                   let dist = helpCardService.distanceMiles(from: userLoc, to: card) {
                    Text(String(format: "%.1f mi", dist))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }

                Text(card.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 400)
        .background(Color(.systemGray6))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
    }

    // MARK: - Empty / Done states

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "rectangle.stack")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text("No cards in this deck")
                .font(.title3)
                .fontWeight(.medium)
            Text("Check back later or try a different deck")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    private var allDoneState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.green)
            Text("You're all caught up!")
                .font(.title3)
                .fontWeight(.medium)
            Text("You've seen all the cards in this deck")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Button("Go Back") { dismiss() }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
                .padding(.top, 8)
            Spacer()
        }
    }

    // MARK: - Actions

    private func performSwipe(_ direction: SwipeDirection, card: HelpCard) {
        let offScreenX: CGFloat = direction == .right ? 500 : -500
        withAnimation(.easeOut(duration: 0.3)) {
            dragOffset = CGSize(width: offScreenX, height: 0)
        }

        Task {
            do {
                if direction == .right {
                    try await helpCardService.swipeRight(cardId: card.id)
                } else {
                    try await helpCardService.swipeLeft(cardId: card.id)
                }
            } catch {
                #if DEBUG
                print("[DeckSwipeView] swipe error: \(error)")
                #endif
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            currentIndex += 1
            dragOffset = .zero
            swipeDirection = nil
        }
    }

    private func loadCards() async {
        isLoading = true
        do {
            switch mode {
            case .urgent:
                cards = try await helpCardService.fetchUrgentCards()
            case .nearby(let radius, let location):
                if let loc = location ?? locationService.currentLocation {
                    cards = try await helpCardService.fetchNearbyCards(
                        userLocation: loc, radiusMiles: radius
                    )
                }
            case .skills(let skills):
                cards = try await helpCardService.fetchSkillCards(skills: skills)
            case .deck(let deckId):
                cards = try await helpCardService.fetchDeckCards(deckId: deckId)
            }
        } catch {
            #if DEBUG
            print("[DeckSwipeView] loadCards error: \(error)")
            #endif
        }
        isLoading = false
    }

    private var modeTitle: String {
        switch mode {
        case .urgent: return "Urgent Today"
        case .nearby: return "Near You"
        case .skills: return "Your Skills"
        case .deck: return "Community Deck"
        }
    }
}
