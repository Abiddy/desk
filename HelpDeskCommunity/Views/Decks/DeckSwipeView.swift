//
//  DeckSwipeView.swift
//  Helpdecks
//

import SwiftUI

struct DeckSwipeView: View {
    let circleId: String
    let circleName: String
    @ObservedObject var helpCardService: HelpCardService
    @Environment(\.dismiss) private var dismiss

    @State private var cards: [HelpCard] = []
    @State private var isLoading = true
    @State private var currentIndex = 0

    private var currentCard: HelpCard? {
        guard currentIndex < cards.count else { return nil }
        return cards[currentIndex]
    }

    private var totalCards: Int { cards.count }

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                Spacer()
                ProgressView("Loading cards...")
                Spacer()
            } else if cards.isEmpty {
                emptyState
            } else if let card = currentCard {
                quizCardView(card: card)
            } else {
                allDoneState
            }
        }
        .background(Color(red: 0.97, green: 0.96, blue: 0.94))
        .navigationTitle("\(circleName) — Urgent Deck")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
        }
        .task { await loadCards() }
    }

    // MARK: - Quiz-card style view

    @ViewBuilder
    private func quizCardView(card: HelpCard) -> some View {
        VStack(spacing: 20) {
            // Progress dots
            progressDots

            // Card
            VStack(alignment: .leading, spacing: 16) {
                // Skill badge
                let skill = HelpCardSkill(rawValue: card.skill) ?? .other
                HStack {
                    Label(skill.rawValue, systemImage: skill.icon)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.purple.opacity(0.12))
                        .foregroundColor(.purple)
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

                // Title as question
                Text(card.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)

                // Description
                Text(card.cardDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)

                Spacer()

                // Author info
                HStack(spacing: 10) {
                    authorAvatar(card: card)
                        .frame(width: 36, height: 36)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(card.authorName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        if let locName = card.locationName {
                            Text(locName)
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
            .frame(maxWidth: .infinity, minHeight: 380)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
            .padding(.horizontal, 20)

            Spacer()

            // Bottom buttons
            HStack {
                Button {
                    goBack()
                } label: {
                    Text("Back")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                }
                .disabled(currentIndex == 0)
                .opacity(currentIndex == 0 ? 0.4 : 1.0)

                Spacer()

                Button {
                    helpAction(card: card)
                } label: {
                    Text("I can help!")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(Color.green)
                        .cornerRadius(24)
                }
            }
            .padding(.horizontal, 24)

            // Skip button
            Button {
                skipAction(card: card)
            } label: {
                Text("Skip")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 24)
            .padding(.top, 8)
        }
        .padding(.top, 12)
    }

    // MARK: - Progress dots

    private var progressDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<min(totalCards, 10), id: \.self) { i in
                SwiftUI.Circle()
                    .fill(i == currentIndex ? Color.purple : Color(.systemGray4))
                    .frame(width: 8, height: 8)
            }
            if totalCards > 10 {
                Text("+\(totalCards - 10)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Avatar

    @ViewBuilder
    private func authorAvatar(card: HelpCard) -> some View {
        if let pic = card.authorProfilePic, !pic.isEmpty {
            AsyncImage(url: URL(string: pic)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Image(systemName: "person.circle.fill").resizable().foregroundColor(.gray)
            }
            .clipShape(SwiftUI.Circle())
        } else {
            Image(systemName: "person.circle.fill")
                .resizable()
                .foregroundColor(.gray)
        }
    }

    // MARK: - States

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "rectangle.stack")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text("No urgent cards in this circle")
                .font(.title3)
                .fontWeight(.medium)
            Text("Check back later!")
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
            Text("You've seen all the urgent cards.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
                .padding(.top, 8)
            Spacer()
        }
    }

    // MARK: - Actions

    private func helpAction(card: HelpCard) {
        Task {
            do {
                try await helpCardService.swipeRight(cardId: card.id)
            } catch {
                #if DEBUG
                print("[DeckSwipeView] swipeRight error: \(error)")
                #endif
            }
        }
        withAnimation(.easeInOut(duration: 0.25)) {
            currentIndex += 1
        }
    }

    private func skipAction(card: HelpCard) {
        Task {
            do {
                try await helpCardService.swipeLeft(cardId: card.id)
            } catch {
                #if DEBUG
                print("[DeckSwipeView] swipeLeft error: \(error)")
                #endif
            }
        }
        withAnimation(.easeInOut(duration: 0.25)) {
            currentIndex += 1
        }
    }

    private func goBack() {
        guard currentIndex > 0 else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            currentIndex -= 1
        }
    }

    private func loadCards() async {
        isLoading = true
        do {
            cards = try await helpCardService.fetchUrgentCards(circleId: circleId)
        } catch {
            #if DEBUG
            print("[DeckSwipeView] loadCards error: \(error)")
            #endif
        }
        isLoading = false
    }
}
