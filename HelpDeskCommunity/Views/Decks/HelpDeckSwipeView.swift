//
//  HelpDeckSwipeView.swift
//  HelpDeskCommunity
//

import SwiftUI

struct HelpDeckSwipeView: View {
    @StateObject private var helpCardService = HelpCardService()
    @State private var cards: [HelpCard] = []
    @State private var isLoading = true
    @State private var currentIndex = 0
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false

    private let swipeThreshold: CGFloat = 120
    private let overlayOpacityScale: CGFloat = 0.8

    private var currentCard: HelpCard? {
        guard currentIndex < cards.count else { return nil }
        return cards[currentIndex]
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let cardMaxHeight = geometry.size.height - 48
                ZStack {
                    Color(red: 0.97, green: 0.96, blue: 0.94)
                        .ignoresSafeArea()

                    if isLoading {
                        ProgressView("Loading cards...")
                    } else if cards.isEmpty {
                        emptyState
                    } else if currentIndex >= cards.count {
                        allDoneState
                    } else if let card = currentCard {
                        cardStack(card: card, maxHeight: cardMaxHeight)
                    }
                }
            }
            .navigationTitle("HelpDeck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { /* Filter - future */ } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .task { await loadCards() }
            .refreshable { await loadCards() }
        }
    }

    // MARK: - Card Stack

    @ViewBuilder
    private func cardStack(card: HelpCard, maxHeight: CGFloat = 400) -> some View {
        ZStack {
            // "I can help" overlay (right swipe - green)
            Text("I can help")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.green.opacity(0.9))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green, lineWidth: 3)
                )
                .rotationEffect(.degrees(-15))
                .opacity(rightSwipeOverlayOpacity)
                .offset(x: 40, y: -80)
                .zIndex(2)

            // "not right now" overlay (left swipe - red)
            Text("not right now")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.red.opacity(0.9))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red, lineWidth: 3)
                )
                .rotationEffect(.degrees(15))
                .opacity(leftSwipeOverlayOpacity)
                .offset(x: -40, y: -80)
                .zIndex(2)

            // Card
            helpCardView(card: card, maxHeight: maxHeight)
                .offset(x: dragOffset.width, y: dragOffset.height * 0.3)
                .rotationEffect(.degrees(Double(dragOffset.width / 20)))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation
                            isDragging = true
                        }
                        .onEnded { value in
                            let width = value.translation.width
                            let velocity = value.predictedEndTranslation.width - width

                            if width > swipeThreshold || (width > 60 && velocity > 200) {
                                performSwipeRight(card: card)
                            } else if width < -swipeThreshold || (width < -60 && velocity < -200) {
                                performSwipeLeft(card: card)
                            } else {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                    dragOffset = .zero
                                    isDragging = false
                                }
                            }
                        }
                )
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    private var rightSwipeOverlayOpacity: Double {
        guard dragOffset.width > 0 else { return 0 }
        let progress = min(1, Double(dragOffset.width / swipeThreshold))
        return progress * overlayOpacityScale
    }

    private var leftSwipeOverlayOpacity: Double {
        guard dragOffset.width < 0 else { return 0 }
        let progress = min(1, Double(-dragOffset.width / swipeThreshold))
        return progress * overlayOpacityScale
    }

    // MARK: - Card Content

    private func helpCardView(card: HelpCard, maxHeight: CGFloat = 400) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Skill badge
            let skill = HelpCardSkill(rawValue: card.skill) ?? .other
            HStack {
                Label(skill.rawValue, systemImage: skill.icon)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.blue.opacity(0.12))
                    .foregroundColor(.blue)
                    .cornerRadius(8)

                if card.urgency == HelpCardUrgency.urgent.rawValue {
                    Label("Urgent", systemImage: "flame.fill")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.red.opacity(0.12))
                        .foregroundColor(.red)
                        .cornerRadius(8)
                }
                Spacer()
            }

            Text(card.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)

            Text(card.cardDescription)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .lineLimit(4)

            Spacer(minLength: 0)

            HStack {
                authorAvatar(card: card)
                    .frame(width: 32, height: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(card.authorName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    if let loc = card.locationName {
                        Text(loc)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Text(card.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 280, maxHeight: maxHeight)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 16, y: 8)
    }

    @ViewBuilder
    private func authorAvatar(card: HelpCard) -> some View {
        Group {
            if let pic = card.authorProfilePic, !pic.isEmpty {
                AsyncImage(url: URL(string: pic)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .foregroundColor(Color(.systemGray3))
                }
                .clipShape(SwiftUI.Circle())
            } else {
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundColor(Color(.systemGray3))
            }
        }
        .frame(width: 32, height: 32)
        .background(Color(.systemGray5))
        .clipShape(SwiftUI.Circle())
    }

    // MARK: - States

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "rectangle.stack")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text("No help cards right now")
                .font(.title3)
                .fontWeight(.medium)
            Text("Check back later or create a card in a circle!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
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
            Text("You've seen all the help cards.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    // MARK: - Actions

    private func performSwipeRight(card: HelpCard) {
        Task {
            do {
                try await helpCardService.swipeRight(cardId: card.id)
            } catch {
                #if DEBUG
                print("[HelpDeckSwipeView] swipeRight error: \(error)")
                #endif
            }
        }
        withAnimation(.easeOut(duration: 0.25)) {
            dragOffset = CGSize(width: 500, height: 0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            currentIndex += 1
            dragOffset = .zero
            isDragging = false
        }
    }

    private func performSwipeLeft(card: HelpCard) {
        Task {
            do {
                try await helpCardService.swipeLeft(cardId: card.id)
            } catch {
                #if DEBUG
                print("[HelpDeckSwipeView] swipeLeft error: \(error)")
                #endif
            }
        }
        withAnimation(.easeOut(duration: 0.25)) {
            dragOffset = CGSize(width: -500, height: 0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            currentIndex += 1
            dragOffset = .zero
            isDragging = false
        }
    }

    private func loadCards() async {
        isLoading = true
        do {
            cards = try await helpCardService.fetchCardsForDeck()
            currentIndex = 0
        } catch {
            #if DEBUG
            print("[HelpDeckSwipeView] loadCards error: \(error)")
            #endif
        }
        isLoading = false
    }
}
