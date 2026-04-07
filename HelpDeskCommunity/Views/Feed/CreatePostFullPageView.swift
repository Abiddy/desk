//
//  CreatePostFullPageView.swift
//  Helpdecks
//
//  Full-screen create post (composer + “Add to your post” group grid with search).
//

import SwiftUI

struct PostableGroup: Identifiable, Hashable {
    let id: String
    let name: String
    let iconName: String
    let iconTint: Color
    let cardTint: Color
}

struct CreatePostFullPageView: View {
    @EnvironmentObject var feedViewModel: FeedViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var circleService = CircleService()

    @Environment(\.dismiss) private var dismiss

    @State private var postTitle = ""
    @State private var postDescription = ""
    @State private var groupSearch = ""
    @State private var groups: [PostableGroup] = []
    @State private var selectedIds: Set<String> = []
    @State private var isLoadingGroups = true
    @State private var isSubmitting = false

    private let maxGroups = 3

    private static let cardPalette: [(Color, Color)] = [
        (.blue, Color.blue.opacity(0.14)),
        (.cyan, Color.cyan.opacity(0.14)),
        (.green, Color.green.opacity(0.14)),
        (.orange, Color.orange.opacity(0.14)),
        (.pink, Color.pink.opacity(0.14)),
        (.purple, Color.purple.opacity(0.14)),
        (.indigo, Color.indigo.opacity(0.14)),
        (.mint, Color.mint.opacity(0.14)),
    ]

    private var filteredGroups: [PostableGroup] {
        let q = groupSearch.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty { return groups }
        return groups.filter {
            $0.name.lowercased().contains(q) || $0.id.lowercased().contains(q)
        }
    }

    private var trimmedTitle: String {
        postTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedDescription: String {
        postDescription.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canPost: Bool {
        !trimmedTitle.isEmpty &&
        !trimmedDescription.isEmpty &&
        !selectedIds.isEmpty &&
        selectedIds.count <= maxGroups &&
        !isSubmitting
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                authorRow

                composerSection

                Divider()

                groupsPanel
            }
            .background(Color(.systemBackground))
            .navigationTitle("Create Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.primary)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await submit() }
                    } label: {
                        Text("Post")
                            .fontWeight(.semibold)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 7)
                            .background(canPost ? Color.blue : Color(.systemGray5))
                            .foregroundStyle(canPost ? Color.white : Color(.systemGray))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(!canPost)
                }
            }
            .task { await loadGroups() }
        }
    }

    // MARK: - Author

    private var authorRow: some View {
        HStack(spacing: 12) {
            authorAvatar
                .frame(width: 44, height: 44)
                .clipShape(SwiftUI.Circle())

            HStack(spacing: 6) {
                Text(authViewModel.authService.currentUser?.name ?? "You")
                    .font(.body)
                    .fontWeight(.semibold)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.blue)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var composerSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            TextField("Add a title…", text: $postTitle)
                .font(.title3)
                .fontWeight(.semibold)
                .textFieldStyle(.plain)

            Rectangle()
                .fill(Color(.separator).opacity(0.35))
                .frame(height: 1)

            ZStack(alignment: .topLeading) {
                if postDescription.isEmpty {
                    Text("Write your description…")
                        .font(.body)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 10)
                        .padding(.leading, 4)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $postDescription)
                    .scrollContentBackground(.hidden)
                    .font(.body)
                    .frame(minHeight: 132)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private var authorAvatar: some View {
        if let urlString = authViewModel.authService.currentUser?.profilePictureURL,
           let url = URL(string: urlString), !urlString.isEmpty {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFit()
                        .padding(10)
                        .foregroundStyle(Color(.systemGray3))
                        .background(Color(.systemGray5))
                }
            }
        } else {
            Image(systemName: "person.fill")
                .resizable()
                .scaledToFit()
                .padding(10)
                .foregroundStyle(Color(.systemGray3))
                .background(Color(.systemGray5))
        }
    }

    // MARK: - Groups

    private var groupsPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add to your post")
                .font(.headline)

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color(.systemGray))
                TextField("Search groups", text: $groupSearch)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .padding(12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Text("Choose \(maxGroups) groups max · \(selectedIds.count) selected")
                .font(.caption)
                .foregroundStyle(.secondary)

            if isLoadingGroups {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                ScrollView {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12),
                        ],
                        spacing: 12
                    ) {
                        ForEach(filteredGroups) { group in
                            groupCard(group)
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(.secondarySystemGroupedBackground))
    }

    private func groupCard(_ group: PostableGroup) -> some View {
        let selected = selectedIds.contains(group.id)
        let atMax = selectedIds.count >= maxGroups
        let disabled = !selected && atMax

        return Button {
            toggleSelection(group.id)
        } label: {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(group.cardTint)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(selected ? Color.blue : Color.clear, lineWidth: 2)
                    )

                HStack {
                    Spacer()
                    Image(systemName: selected ? "checkmark.circle.fill" : "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(selected ? Color.blue : Color.secondary)
                }
                .padding(10)

                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: group.iconName)
                        .font(.system(size: 22))
                        .foregroundStyle(group.iconTint)
                        .frame(width: 36, height: 36)
                        .background(group.iconTint.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    Text(group.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(disabled ? .tertiary : .primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
                .padding(12)
                .padding(.trailing, 24)
            }
            .frame(height: 108)
            .opacity(disabled ? 0.45 : 1)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    private func toggleSelection(_ id: String) {
        if selectedIds.contains(id) {
            selectedIds.remove(id)
        } else if selectedIds.count < maxGroups {
            selectedIds.insert(id)
        }
    }

    private func loadGroups() async {
        isLoadingGroups = true
        var merged: [PostableGroup] = []

        for (index, cat) in CircleCategory.allCases.enumerated() {
            let palette = Self.cardPalette[index % Self.cardPalette.count]
            merged.append(
                PostableGroup(
                    id: "circle_\(cat.rawValue.lowercased())",
                    name: cat.rawValue,
                    iconName: cat.icon,
                    iconTint: palette.0,
                    cardTint: palette.1
                )
            )
        }

        do {
            let remote = try await circleService.fetchPublicCircles()
            let existing = Set(merged.map { $0.name.lowercased() })
            var idx = merged.count
            for circle in remote {
                let lower = circle.name.lowercased()
                if existing.contains(lower) { continue }
                let palette = Self.cardPalette[idx % Self.cardPalette.count]
                merged.append(
                    PostableGroup(
                        id: circle.id,
                        name: circle.name,
                        iconName: circle.iconName,
                        iconTint: palette.0,
                        cardTint: palette.1
                    )
                )
                idx += 1
            }
        } catch {
            #if DEBUG
            print("[CreatePostFullPageView] fetchPublicCircles: \(error)")
            #endif
        }

        merged.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        groups = merged
        isLoadingGroups = false
    }

    private func submit() async {
        guard canPost else { return }
        isSubmitting = true
        let title = trimmedTitle
        let body = trimmedDescription
        let picks = groups.filter { selectedIds.contains($0.id) }
        var anySuccess = false
        for group in picks {
            let ok = await feedViewModel.createPost(
                circleId: group.id,
                circleName: group.name,
                title: title,
                body: body
            )
            if ok { anySuccess = true }
        }
        isSubmitting = false
        if anySuccess { dismiss() }
    }
}
