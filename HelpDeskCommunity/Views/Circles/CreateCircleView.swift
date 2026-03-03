//
//  CreateCircleView.swift
//  Helpdecks
//

import SwiftUI

struct CreateCircleView: View {
    @ObservedObject var circleService: CircleService
    var onCreated: (() async -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var description = ""
    @State private var isPublic = true
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Circle Details") {
                    TextField("Name (e.g. UIC MSA)", text: $name)
                    TextEditor(text: $description)
                        .frame(minHeight: 80)
                }

                Section("Visibility") {
                    Picker("Type", selection: $isPublic) {
                        Text("Public").tag(true)
                        Text("Private (Invite Only)").tag(false)
                    }
                    .pickerStyle(.segmented)

                    if !isPublic {
                        Text("An invite code will be generated so others can join.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("New Circle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { Task { await submit() } }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func submit() async {
        isSubmitting = true
        errorMessage = nil
        do {
            _ = try await circleService.createCircle(
                name: name.trimmingCharacters(in: .whitespaces),
                description: description.trimmingCharacters(in: .whitespaces),
                isPublic: isPublic
            )
            await onCreated?()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }
}
