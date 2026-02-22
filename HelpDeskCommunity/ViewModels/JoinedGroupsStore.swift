//
//  JoinedGroupsStore.swift
//  HelpDeskCommunity
//

import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

/// Holds which groups the user has joined.
/// Persisted locally (UserDefaults) and synced to Firestore.
@MainActor
class JoinedGroupsStore: ObservableObject {
    @Published var joinedGroupIds: Set<String>

    private let localKey = "joinedGroupIds"
    private let db = Firestore.firestore()

    init() {
        let raw = UserDefaults.standard.stringArray(forKey: localKey) ?? []
        self.joinedGroupIds = Set(raw)
        if joinedGroupIds.isEmpty {
            joinedGroupIds = Set(GroupCategory.allCases.map { $0.rawValue.lowercased() })
            saveLocal()
        }
    }

    // MARK: - Public API

    func isJoined(_ groupId: String) -> Bool {
        joinedGroupIds.contains(groupId.lowercased())
    }

    func toggle(_ groupId: String) {
        let id = groupId.lowercased()
        if joinedGroupIds.contains(id) {
            joinedGroupIds.remove(id)
        } else {
            joinedGroupIds.insert(id)
        }
        saveLocal()
        Task { await syncToFirestore() }
    }

    func setJoined(_ groupId: String, _ joined: Bool) {
        let id = groupId.lowercased()
        if joined {
            joinedGroupIds.insert(id)
        } else {
            joinedGroupIds.remove(id)
        }
        saveLocal()
        Task { await syncToFirestore() }
    }

    // MARK: - Firestore sync

    /// Pull joinedGroupIds from Firestore (call after sign-in).
    func loadFromFirestore() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            let doc = try await db.collection("users").document(uid).getDocument()
            if let ids = doc.data()?["joinedGroupIds"] as? [String], !ids.isEmpty {
                joinedGroupIds = Set(ids)
                saveLocal()
            } else {
                // First time: push local defaults to Firestore
                await syncToFirestore()
            }
        } catch {
            #if DEBUG
            print("[JoinedGroupsStore] loadFromFirestore error: \(error)")
            #endif
        }
    }

    private func syncToFirestore() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        try? await db.collection("users").document(uid)
            .updateData(["joinedGroupIds": Array(joinedGroupIds)])
    }

    private func saveLocal() {
        UserDefaults.standard.set(Array(joinedGroupIds), forKey: localKey)
    }
}
