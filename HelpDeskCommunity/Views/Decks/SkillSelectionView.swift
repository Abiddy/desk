//
//  SkillSelectionView.swift
//  HelpDeskCommunity
//

import SwiftUI

struct SkillSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("userSkills") private var userSkillsData: Data = Data()

    @State private var selectedSkills: Set<String> = []

    var body: some View {
        List {
            Section {
                Text("Select the skills you can help others with. You'll see matching Help Cards in your \"Your Skills\" deck.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Section("Available Skills") {
                ForEach(HelpCardSkill.allCases) { skill in
                    Button {
                        if selectedSkills.contains(skill.rawValue) {
                            selectedSkills.remove(skill.rawValue)
                        } else {
                            selectedSkills.insert(skill.rawValue)
                        }
                    } label: {
                        HStack {
                            Label(skill.rawValue, systemImage: skill.icon)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedSkills.contains(skill.rawValue) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.purple)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Your Skills")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    if let data = try? JSONEncoder().encode(Array(selectedSkills)) {
                        userSkillsData = data
                    }
                    dismiss()
                }
                .fontWeight(.semibold)
            }
        }
        .onAppear {
            if let skills = try? JSONDecoder().decode([String].self, from: userSkillsData) {
                selectedSkills = Set(skills)
            }
        }
    }
}
