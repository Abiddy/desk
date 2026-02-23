//
//  CreateDeckView.swift
//  HelpDeskCommunity
//

import SwiftUI

struct CreateDeckView: View {
    @ObservedObject var deckService: DeckService
    var onCreated: (Deck) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var description = ""
    @State private var isPublic = true
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Deck Info") {
                    TextField("Name (e.g. UIC MSA)", text: $name)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Visibility") {
                    Picker("Who can join?", selection: $isPublic) {
                        Text("Public — anyone can join").tag(true)
                        Text("Private — invite code only").tag(false)
                    }
                    .pickerStyle(.inline)

                    if !isPublic {
                        Label("An invite code will be generated automatically", systemImage: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Create a Deck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task { await submit() }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func submit() async {
        isSubmitting = true
        do {
            let deck = try await deckService.createDeck(
                name: name.trimmingCharacters(in: .whitespaces),
                description: description.trimmingCharacters(in: .whitespaces),
                isPublic: isPublic
            )
            onCreated(deck)
            dismiss()
        } catch {
            #if DEBUG
            print("[CreateDeckView] submit error: \(error)")
            #endif
        }
        isSubmitting = false
    }
}
