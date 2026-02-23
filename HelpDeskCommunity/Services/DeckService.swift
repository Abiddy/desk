//
//  DeckService.swift
//  HelpDeskCommunity
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
class DeckService: ObservableObject {
    private let db = Firestore.firestore()
    private var decksCollection: CollectionReference { db.collection("decks") }

    // MARK: - Create

    func createDeck(name: String, description: String, isPublic: Bool) async throws -> Deck {
        guard let userId = Auth.auth().currentUser?.uid else { throw PostError.notAuthenticated }

        let inviteCode = isPublic ? nil : generateInviteCode()

        let deck = Deck(
            name: name,
            deckDescription: description,
            type: isPublic ? DeckType.userPublic.rawValue : DeckType.userPrivate.rawValue,
            creatorId: userId,
            adminIds: [userId],
            memberIds: [userId],
            inviteCode: inviteCode,
            isPublic: isPublic
        )

        let data: [String: Any] = [
            "id": deck.id,
            "name": deck.name,
            "deckDescription": deck.deckDescription,
            "iconName": deck.iconName,
            "type": deck.type,
            "creatorId": deck.creatorId as Any,
            "adminIds": deck.adminIds,
            "memberIds": deck.memberIds,
            "inviteCode": deck.inviteCode as Any,
            "isPublic": deck.isPublic,
            "createdAt": Timestamp(date: deck.createdAt)
        ]

        try await decksCollection.document(deck.id).setData(data)
        return deck
    }

    // MARK: - Fetch

    /// All decks the current user is a member of.
    func fetchMyDecks() async throws -> [Deck] {
        guard let userId = Auth.auth().currentUser?.uid else { return [] }

        let snapshot = try await decksCollection
            .whereField("memberIds", arrayContains: userId)
            .getDocuments()

        return snapshot.documents
            .compactMap { deckFromDocument($0) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    /// Public decks available to join.
    func fetchPublicDecks() async throws -> [Deck] {
        let snapshot = try await decksCollection
            .whereField("isPublic", isEqualTo: true)
            .getDocuments()

        return snapshot.documents
            .compactMap { deckFromDocument($0) }
            .sorted { $0.memberIds.count > $1.memberIds.count }
    }

    // MARK: - Join / Leave

    func joinDeck(deckId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { throw PostError.notAuthenticated }
        try await decksCollection.document(deckId)
            .updateData(["memberIds": FieldValue.arrayUnion([userId])])
    }

    func joinDeckByInviteCode(_ code: String) async throws -> Deck? {
        guard let userId = Auth.auth().currentUser?.uid else { throw PostError.notAuthenticated }

        let snapshot = try await decksCollection
            .whereField("inviteCode", isEqualTo: code)
            .getDocuments()

        guard let doc = snapshot.documents.first,
              let deck = deckFromDocument(doc) else { return nil }

        try await decksCollection.document(deck.id)
            .updateData(["memberIds": FieldValue.arrayUnion([userId])])

        return deck
    }

    func leaveDeck(deckId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { throw PostError.notAuthenticated }
        try await decksCollection.document(deckId)
            .updateData(["memberIds": FieldValue.arrayRemove([userId])])
    }

    // MARK: - Card count for a deck

    func cardCount(deckId: String) async throws -> Int {
        let snapshot = try await db.collection("helpCards")
            .whereField("deckId", isEqualTo: deckId)
            .whereField("status", isEqualTo: HelpCardStatus.open.rawValue)
            .getDocuments()
        return snapshot.count
    }

    // MARK: - Helpers

    private func generateInviteCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).map { _ in chars.randomElement()! })
    }

    private func deckFromDocument(_ doc: QueryDocumentSnapshot) -> Deck? {
        let d = doc.data()
        return Deck(
            id: d["id"] as? String ?? doc.documentID,
            name: d["name"] as? String ?? "",
            deckDescription: d["deckDescription"] as? String ?? "",
            iconName: d["iconName"] as? String ?? "rectangle.stack.fill",
            type: d["type"] as? String ?? DeckType.userPublic.rawValue,
            creatorId: d["creatorId"] as? String,
            adminIds: d["adminIds"] as? [String] ?? [],
            memberIds: d["memberIds"] as? [String] ?? [],
            inviteCode: d["inviteCode"] as? String,
            isPublic: d["isPublic"] as? Bool ?? true,
            createdAt: (d["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}
