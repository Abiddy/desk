//
//  CreateHelpCardView.swift
//  HelpDeskCommunity
//

import SwiftUI

struct CreateHelpCardView: View {
    @ObservedObject var helpCardService: HelpCardService
    @EnvironmentObject var locationService: LocationService
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var selectedSkill: HelpCardSkill = .other
    @State private var urgency: HelpCardUrgency = .normal
    @State private var isRemote = false
    @State private var useMyLocation = true
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            Form {
                Section("What do you need help with?") {
                    TextField("Title", text: $title)
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                }

                Section("Category") {
                    Picker("Skill needed", selection: $selectedSkill) {
                        ForEach(HelpCardSkill.allCases) { skill in
                            Label(skill.rawValue, systemImage: skill.icon)
                                .tag(skill)
                        }
                    }
                }

                Section("Urgency") {
                    Picker("How urgent?", selection: $urgency) {
                        ForEach(HelpCardUrgency.allCases, id: \.rawValue) { u in
                            Text(u.rawValue).tag(u)
                        }
                    }
                    .pickerStyle(.segmented)

                    if urgency == .urgent {
                        Label("This card will expire at the end of today", systemImage: "clock.badge.exclamationmark")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }

                Section("Location") {
                    Toggle("Can be done remotely", isOn: $isRemote)

                    if !isRemote {
                        Toggle("Use my current location", isOn: $useMyLocation)
                        if useMyLocation, let locString = locationService.locationString {
                            Label(locString, systemImage: "mappin.circle.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("New Help Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        Task { await submit() }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func submit() async {
        isSubmitting = true
        do {
            let lat = useMyLocation && !isRemote ? locationService.currentLocation?.coordinate.latitude : nil
            let lng = useMyLocation && !isRemote ? locationService.currentLocation?.coordinate.longitude : nil
            let locName = useMyLocation && !isRemote ? locationService.locationString : nil

            _ = try await helpCardService.createCard(
                title: title.trimmingCharacters(in: .whitespaces),
                description: description.trimmingCharacters(in: .whitespaces),
                skill: selectedSkill,
                urgency: urgency,
                isRemote: isRemote,
                latitude: lat,
                longitude: lng,
                locationName: locName,
                deckId: nil
            )
            dismiss()
        } catch {
            #if DEBUG
            print("[CreateHelpCardView] submit error: \(error)")
            #endif
        }
        isSubmitting = false
    }
}
