//
//  HelpCardService.swift
//  Helpdecks
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import CoreLocation

@MainActor
class HelpCardService: ObservableObject {
    private let db = Firestore.firestore()
    private var cardsCollection: CollectionReference { db.collection("helpCards") }

    // MARK: - Create

    func createCard(
        title: String,
        description: String,
        skill: HelpCardSkill,
        urgency: HelpCardUrgency,
        isRemote: Bool,
        latitude: Double?,
        longitude: Double?,
        locationName: String?,
        circleId: String?
    ) async throws -> HelpCard {
        guard let user = Auth.auth().currentUser else { throw PostError.notAuthenticated }

        let userDoc = try await db.collection("users").document(user.uid).getDocument()
        let userName = userDoc.data()?["name"] as? String ?? "Unknown"
        let userPic = userDoc.data()?["profilePictureURL"] as? String

        var expiresAt: Date? = nil
        if urgency == .urgent {
            expiresAt = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: Date())
        }

        let card = HelpCard(
            authorId: user.uid,
            authorName: userName,
            authorProfilePic: userPic,
            title: title,
            cardDescription: description,
            skill: skill.rawValue,
            urgency: urgency.rawValue,
            isRemote: isRemote,
            latitude: latitude,
            longitude: longitude,
            locationName: locationName,
            circleId: circleId,
            expiresAt: expiresAt
        )

        let data: [String: Any] = [
            "id": card.id,
            "authorId": card.authorId,
            "authorName": card.authorName,
            "authorProfilePic": card.authorProfilePic as Any,
            "title": card.title,
            "cardDescription": card.cardDescription,
            "skill": card.skill,
            "urgency": card.urgency,
            "isRemote": card.isRemote,
            "latitude": card.latitude as Any,
            "longitude": card.longitude as Any,
            "locationName": card.locationName as Any,
            "circleId": card.circleId as Any,
            "status": card.status,
            "swipedRightUserIds": card.swipedRightUserIds,
            "swipedLeftUserIds": card.swipedLeftUserIds,
            "timestamp": Timestamp(date: card.timestamp),
            "expiresAt": card.expiresAt.map { Timestamp(date: $0) } as Any
        ]

        try await cardsCollection.document(card.id).setData(data)
        return card
    }

    // MARK: - Fetch

    func fetchCards(limit: Int = 100) async throws -> [HelpCard] {
        let snapshot = try await cardsCollection
            .whereField("status", isEqualTo: HelpCardStatus.open.rawValue)
            .getDocuments()

        return snapshot.documents
            .compactMap { cardFromDocument($0) }
            .sorted { $0.timestamp > $1.timestamp }
    }

    /// Urgent cards for a specific circle.
    func fetchUrgentCards(circleId: String) async throws -> [HelpCard] {
        let userId = Auth.auth().currentUser?.uid ?? ""
        let allCards = try await fetchCards(limit: 200)

        let now = Date()
        return allCards.filter { card in
            card.circleId == circleId &&
            card.urgency == HelpCardUrgency.urgent.rawValue &&
            card.authorId != userId &&
            !card.swipedRightUserIds.contains(userId) &&
            !card.swipedLeftUserIds.contains(userId) &&
            (card.expiresAt == nil || card.expiresAt! > now)
        }
    }

    /// All cards for a specific circle (not just urgent).
    func fetchCircleCards(circleId: String) async throws -> [HelpCard] {
        let userId = Auth.auth().currentUser?.uid ?? ""
        let allCards = try await fetchCards(limit: 200)

        return allCards.filter { card in
            card.circleId == circleId &&
            card.authorId != userId &&
            !card.swipedRightUserIds.contains(userId) &&
            !card.swipedLeftUserIds.contains(userId)
        }
    }

    /// Cards from all circles for the HelpDeck swipe page (user hasn't swiped yet).
    func fetchCardsForDeck(limit: Int = 100) async throws -> [HelpCard] {
        let userId = Auth.auth().currentUser?.uid ?? ""
        let allCards = try await fetchCards(limit: limit)

        return allCards.filter { card in
            card.authorId != userId &&
            !card.swipedRightUserIds.contains(userId) &&
            !card.swipedLeftUserIds.contains(userId)
        }
    }

    // MARK: - Swipe actions

    func swipeRight(cardId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { throw PostError.notAuthenticated }
        try await cardsCollection.document(cardId)
            .updateData(["swipedRightUserIds": FieldValue.arrayUnion([userId])])
    }

    func swipeLeft(cardId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { throw PostError.notAuthenticated }
        try await cardsCollection.document(cardId)
            .updateData(["swipedLeftUserIds": FieldValue.arrayUnion([userId])])
    }

    // MARK: - Helpers

    private func cardFromDocument(_ doc: QueryDocumentSnapshot) -> HelpCard? {
        let d = doc.data()
        return HelpCard(
            id: d["id"] as? String ?? doc.documentID,
            authorId: d["authorId"] as? String ?? "",
            authorName: d["authorName"] as? String ?? "Unknown",
            authorProfilePic: d["authorProfilePic"] as? String,
            title: d["title"] as? String ?? "",
            cardDescription: d["cardDescription"] as? String ?? "",
            skill: d["skill"] as? String ?? HelpCardSkill.other.rawValue,
            urgency: d["urgency"] as? String ?? HelpCardUrgency.normal.rawValue,
            isRemote: d["isRemote"] as? Bool ?? false,
            latitude: d["latitude"] as? Double,
            longitude: d["longitude"] as? Double,
            locationName: d["locationName"] as? String,
            circleId: d["circleId"] as? String ?? d["deckId"] as? String,
            status: d["status"] as? String ?? HelpCardStatus.open.rawValue,
            swipedRightUserIds: d["swipedRightUserIds"] as? [String] ?? [],
            swipedLeftUserIds: d["swipedLeftUserIds"] as? [String] ?? [],
            timestamp: (d["timestamp"] as? Timestamp)?.dateValue() ?? Date(),
            expiresAt: (d["expiresAt"] as? Timestamp)?.dateValue()
        )
    }
}
