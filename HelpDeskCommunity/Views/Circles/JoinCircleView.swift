//
//  JoinCircleView.swift
//  Helpdecks
//

import SwiftUI

struct JoinCircleView: View {
    @ObservedObject var circleService: CircleService
    var onJoined: (() async -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    @State private var inviteCode = ""
    @State private var isSubmitting = false
    @State private var resultMessage: String?
    @State private var isError = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "ticket.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.purple)

                Text("Join a Circle")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Enter the 6-character invite code to join a private circle.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                TextField("Invite Code", text: $inviteCode)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.characters)
                    .frame(maxWidth: 200)
                    .multilineTextAlignment(.center)
                    .font(.title3.monospaced())

                if let msg = resultMessage {
                    Text(msg)
                        .font(.caption)
                        .foregroundColor(isError ? .red : .green)
                }

                Button {
                    Task { await joinWithCode() }
                } label: {
                    HStack {
                        if isSubmitting {
                            ProgressView().tint(.white)
                        }
                        Text("Join")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(inviteCode.count >= 6 ? Color.purple : Color.gray.opacity(0.3))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(inviteCode.count < 6 || isSubmitting)
                .padding(.horizontal, 40)

                Spacer()
            }
            .navigationTitle("Join Circle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func joinWithCode() async {
        isSubmitting = true
        resultMessage = nil
        do {
            if let circle = try await circleService.joinByInviteCode(inviteCode.uppercased()) {
                resultMessage = "Joined \(circle.name)!"
                isError = false
                await onJoined?()
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                dismiss()
            } else {
                resultMessage = "No circle found with that code."
                isError = true
            }
        } catch {
            resultMessage = error.localizedDescription
            isError = true
        }
        isSubmitting = false
    }
}
