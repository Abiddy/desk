//
//  CreatePostView.swift
//  HelpDeskCommunity
//

import SwiftUI

struct CreatePostView: View {
    @EnvironmentObject var feedViewModel: FeedViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategory: GroupCategory = .classifieds
    @State private var title = ""
    @State private var postBody = ""
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Group") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(GroupCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                }

                Section("Post") {
                    TextField("Title", text: $title)
                    TextEditor(text: $postBody)
                        .frame(minHeight: 120)
                }
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") { Task { await submit() } }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func submit() async {
        isSubmitting = true
        let groupId = selectedCategory.rawValue.lowercased()
        let success = await feedViewModel.createPost(
            groupId: groupId,
            groupCategory: selectedCategory.rawValue,
            title: title.trimmingCharacters(in: .whitespaces),
            body: postBody.trimmingCharacters(in: .whitespaces)
        )
        isSubmitting = false
        if success { dismiss() }
    }
}
