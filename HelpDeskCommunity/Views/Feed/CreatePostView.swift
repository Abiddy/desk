//
//  CreatePostView.swift
//  Helpdecks
//

import SwiftUI

struct CreatePostView: View {
    @EnvironmentObject var feedViewModel: FeedViewModel
    @Environment(\.dismiss) private var dismiss

    var preselectedCircle: CircleCategory? = nil
    @State private var selectedCategory: CircleCategory = .tech
    @State private var title = ""
    @State private var postBody = ""
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Circle") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(CircleCategory.allCases) { category in
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
            .onAppear {
                if let pre = preselectedCircle {
                    selectedCategory = pre
                }
            }
        }
    }

    private func submit() async {
        isSubmitting = true
        let circleId = selectedCategory.rawValue.lowercased()
        let success = await feedViewModel.createPost(
            circleId: circleId,
            circleName: selectedCategory.rawValue,
            title: title.trimmingCharacters(in: .whitespaces),
            body: postBody.trimmingCharacters(in: .whitespaces)
        )
        isSubmitting = false
        if success { dismiss() }
    }
}
