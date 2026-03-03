//
//  JoinedCirclesStore.swift
//  Helpdecks
//

import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

@MainActor
class JoinedCirclesStore: ObservableObject {
    @Published var joinedCircleIds: Set<String>

    private let localKey = "joinedCircleIds"
    private let db = Firestore.firestore()

    init() {
        let raw = UserDefaults.standard.stringArray(forKey: localKey) ?? []
        self.joinedCircleIds = Set(raw)
        if joinedCircleIds.isEmpty {
            joinedCircleIds = Set(CircleCategory.allCases.map { $0.rawValue.lowercased() })
            saveLocal()
        }
    }

    func isJoined(_ circleId: String) -> Bool {
        joinedCircleIds.contains(circleId.lowercased())
    }

    func toggle(_ circleId: String) {
        let id = circleId.lowercased()
        if joinedCircleIds.contains(id) {
            joinedCircleIds.remove(id)
        } else {
            joinedCircleIds.insert(id)
        }
        saveLocal()
        Task { await syncToFirestore() }
    }

    func setJoined(_ circleId: String, _ joined: Bool) {
        let id = circleId.lowercased()
        if joined {
            joinedCircleIds.insert(id)
        } else {
            joinedCircleIds.remove(id)
        }
        saveLocal()
        Task { await syncToFirestore() }
    }

    func loadFromFirestore() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            let doc = try await db.collection("users").document(uid).getDocument()
            if let ids = doc.data()?["joinedCircleIds"] as? [String], !ids.isEmpty {
                joinedCircleIds = Set(ids)
                saveLocal()
            } else {
                await syncToFirestore()
            }
        } catch {
            #if DEBUG
            print("[JoinedCirclesStore] loadFromFirestore error: \(error)")
            #endif
        }
    }

    private func syncToFirestore() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        try? await db.collection("users").document(uid)
            .updateData(["joinedCircleIds": Array(joinedCircleIds)])
    }

    private func saveLocal() {
        UserDefaults.standard.set(Array(joinedCircleIds), forKey: localKey)
    }
}
