//
//  FollowService.swift
//  HelpDeskCommunity
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
class FollowService: ObservableObject {
    @Published var followingUserIds: Set<String> = []

    private let db = Firestore.firestore()

    func loadFollowing() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            let doc = try await db.collection("users").document(uid).getDocument()
            let ids = doc.data()?["followingUserIds"] as? [String] ?? []
            followingUserIds = Set(ids)
        } catch {
            #if DEBUG
            print("[FollowService] loadFollowing error: \(error)")
            #endif
        }
    }

    func isFollowing(_ userId: String) -> Bool {
        followingUserIds.contains(userId)
    }

    func toggleFollow(_ userId: String) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let ref = db.collection("users").document(uid)

        if followingUserIds.contains(userId) {
            followingUserIds.remove(userId)
            try? await ref.updateData(["followingUserIds": FieldValue.arrayRemove([userId])])
        } else {
            followingUserIds.insert(userId)
            try? await ref.updateData(["followingUserIds": FieldValue.arrayUnion([userId])])
        }
    }
}
