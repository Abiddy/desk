//
//  JoinDeckView.swift
//  HelpDeskCommunity
//

import SwiftUI

struct JoinDeckView: View {
    @ObservedObject var deckService: DeckService
    var onJoined: (Deck) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var inviteCode = ""
    @State private var publicDecks: [Deck] = []
    @State private var errorMessage: String?
    @State private var isJoining = false

    var body: some View {
        NavigationStack {
            List {
                Section("Join with Invite Code") {
                    HStack {
                        TextField("Enter 6-digit code", text: $inviteCode)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()

                        Button("Join") {
                            Task { await joinWithCode() }
                        }
                        .disabled(inviteCode.count < 6 || isJoining)
                        .fontWeight(.semibold)
                    }

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                if !publicDecks.isEmpty {
                    Section("Public Decks") {
                        ForEach(publicDecks, id: \.id) { deck in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(deck.name)
                                        .fontWeight(.medium)
                                    Text("\(deck.memberIds.count) members")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Button("Join") {
                                    Task { await joinPublicDeck(deck) }
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.purple)
                                .controlSize(.small)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Join a Deck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                do {
                    publicDecks = try await deckService.fetchPublicDecks()
                } catch {
                    #if DEBUG
                    print("[JoinDeckView] fetchPublicDecks error: \(error)")
                    #endif
                }
            }
        }
    }

    private func joinWithCode() async {
        isJoining = true
        errorMessage = nil
        do {
            if let deck = try await deckService.joinDeckByInviteCode(inviteCode.uppercased()) {
                onJoined(deck)
                dismiss()
            } else {
                errorMessage = "No deck found with that code."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isJoining = false
    }

    private func joinPublicDeck(_ deck: Deck) async {
        do {
            try await deckService.joinDeck(deckId: deck.id)
            onJoined(deck)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
