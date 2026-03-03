//
//  CircleService.swift
//  Helpdecks
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
class CircleService: ObservableObject {
    private let db = Firestore.firestore()
    private var circlesCollection: CollectionReference { db.collection("circles") }

    // MARK: - Create

    func createCircle(name: String, description: String, isPublic: Bool) async throws -> Circle {
        guard let userId = Auth.auth().currentUser?.uid else { throw PostError.notAuthenticated }

        let inviteCode = isPublic ? nil : generateInviteCode()

        let circle = Circle(
            name: name,
            circleDescription: description,
            creatorId: userId,
            adminIds: [userId],
            memberIds: [userId],
            inviteCode: inviteCode,
            isPublic: isPublic
        )

        let data: [String: Any] = [
            "id": circle.id,
            "name": circle.name,
            "circleDescription": circle.circleDescription,
            "iconName": circle.iconName,
            "category": circle.category,
            "creatorId": circle.creatorId as Any,
            "adminIds": circle.adminIds,
            "memberIds": circle.memberIds,
            "followerCount": circle.followerCount,
            "isPromoted": circle.isPromoted,
            "inviteCode": circle.inviteCode as Any,
            "isPublic": circle.isPublic,
            "createdAt": Timestamp(date: circle.createdAt)
        ]

        try await circlesCollection.document(circle.id).setData(data)
        return circle
    }

    // MARK: - Fetch

    func fetchPromotedCircles() async throws -> [Circle] {
        let snapshot = try await circlesCollection
            .whereField("isPromoted", isEqualTo: true)
            .getDocuments()

        return snapshot.documents
            .compactMap { circleFromDocument($0) }
            .sorted { $0.followerCount > $1.followerCount }
    }

    func fetchMyCircles() async throws -> [Circle] {
        guard let userId = Auth.auth().currentUser?.uid else { return [] }

        let snapshot = try await circlesCollection
            .whereField("memberIds", arrayContains: userId)
            .getDocuments()

        return snapshot.documents
            .compactMap { circleFromDocument($0) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func fetchPublicCircles() async throws -> [Circle] {
        let snapshot = try await circlesCollection
            .whereField("isPublic", isEqualTo: true)
            .getDocuments()

        return snapshot.documents
            .compactMap { circleFromDocument($0) }
            .sorted { $0.followerCount > $1.followerCount }
    }

    // MARK: - Join / Leave

    func joinCircle(circleId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { throw PostError.notAuthenticated }
        try await circlesCollection.document(circleId)
            .updateData([
                "memberIds": FieldValue.arrayUnion([userId]),
                "followerCount": FieldValue.increment(Int64(1))
            ])
    }

    func leaveCircle(circleId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { throw PostError.notAuthenticated }
        try await circlesCollection.document(circleId)
            .updateData([
                "memberIds": FieldValue.arrayRemove([userId]),
                "followerCount": FieldValue.increment(Int64(-1))
            ])
    }

    func joinByInviteCode(_ code: String) async throws -> Circle? {
        guard let userId = Auth.auth().currentUser?.uid else { throw PostError.notAuthenticated }

        let snapshot = try await circlesCollection
            .whereField("inviteCode", isEqualTo: code)
            .getDocuments()

        guard let doc = snapshot.documents.first,
              let circle = circleFromDocument(doc) else { return nil }

        try await circlesCollection.document(circle.id)
            .updateData([
                "memberIds": FieldValue.arrayUnion([userId]),
                "followerCount": FieldValue.increment(Int64(1))
            ])

        return circle
    }

    /// Count of urgent help cards in a circle.
    func urgentCardCount(circleId: String) async throws -> Int {
        let snapshot = try await db.collection("helpCards")
            .whereField("circleId", isEqualTo: circleId)
            .whereField("status", isEqualTo: HelpCardStatus.open.rawValue)
            .whereField("urgency", isEqualTo: HelpCardUrgency.urgent.rawValue)
            .getDocuments()
        return snapshot.count
    }

    // MARK: - Helpers

    private func generateInviteCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).map { _ in chars.randomElement()! })
    }

    private func circleFromDocument(_ doc: QueryDocumentSnapshot) -> Circle? {
        let d = doc.data()
        return Circle(
            id: d["id"] as? String ?? doc.documentID,
            name: d["name"] as? String ?? "",
            circleDescription: d["circleDescription"] as? String ?? d["deckDescription"] as? String ?? "",
            iconName: d["iconName"] as? String ?? "circle.grid.3x3.fill",
            category: d["category"] as? String ?? "",
            creatorId: d["creatorId"] as? String,
            adminIds: d["adminIds"] as? [String] ?? [],
            memberIds: d["memberIds"] as? [String] ?? [],
            followerCount: d["followerCount"] as? Int ?? (d["memberIds"] as? [String])?.count ?? 0,
            isPromoted: d["isPromoted"] as? Bool ?? false,
            inviteCode: d["inviteCode"] as? String,
            isPublic: d["isPublic"] as? Bool ?? true,
            createdAt: (d["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}
