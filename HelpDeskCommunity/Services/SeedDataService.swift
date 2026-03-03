//
//  SeedDataService.swift
//  Helpdecks
//
//  DEBUG-only service to populate Firestore with dummy data for testing.
//

import Foundation
import FirebaseFirestore

@MainActor
class SeedDataService {
    private let db = Firestore.firestore()

    func seedAll() async throws {
        try await seedUsers()
        try await seedCircles()
        try await seedPosts()
        try await seedHelpCards()
    }

    static func seedIfNeeded() async {
        let db = Firestore.firestore()
        do {
            let snap = try await db.collection("circles").limit(to: 1).getDocuments()
            if snap.documents.isEmpty {
                try await SeedDataService().seedAll()
            }
        } catch {
            #if DEBUG
            print("[SeedDataService] seedIfNeeded error: \(error)")
            #endif
        }
    }

    // MARK: - Users

    private let dummyUsers: [[String: Any]] = [
        ["id": "seed_user_1", "name": "Aisha Khan", "email": "aisha@test.com", "isEmailVerified": true,
         "location": "Chicago, IL", "latitude": 41.8781, "longitude": -87.6298,
         "profilePictureURL": "", "createdAt": Timestamp(), "lastSeen": Timestamp(),
         "blockedUsers": [], "followingUserIds": [], "joinedCircleIds": ["tech", "medical", "legal"]],

        ["id": "seed_user_2", "name": "Omar Farooq", "email": "omar@test.com", "isEmailVerified": true,
         "location": "Houston, TX", "latitude": 29.7604, "longitude": -95.3698,
         "profilePictureURL": "", "createdAt": Timestamp(), "lastSeen": Timestamp(),
         "blockedUsers": [], "followingUserIds": [], "joinedCircleIds": ["tech", "business", "medical"]],

        ["id": "seed_user_3", "name": "Fatima Ali", "email": "fatima@test.com", "isEmailVerified": true,
         "location": "Dallas, TX", "latitude": 32.7767, "longitude": -96.7970,
         "profilePictureURL": "", "createdAt": Timestamp(), "lastSeen": Timestamp(),
         "blockedUsers": [], "followingUserIds": [], "joinedCircleIds": ["medical", "legal", "business"]],

        ["id": "seed_user_4", "name": "Yusuf Ahmed", "email": "yusuf@test.com", "isEmailVerified": true,
         "location": "New York, NY", "latitude": 40.7128, "longitude": -74.0060,
         "profilePictureURL": "", "createdAt": Timestamp(), "lastSeen": Timestamp(),
         "blockedUsers": [], "followingUserIds": [], "joinedCircleIds": ["business", "tech", "legal"]],

        ["id": "seed_user_5", "name": "Maryam Hassan", "email": "maryam@test.com", "isEmailVerified": true,
         "location": "Los Angeles, CA", "latitude": 34.0522, "longitude": -118.2437,
         "profilePictureURL": "", "createdAt": Timestamp(), "lastSeen": Timestamp(),
         "blockedUsers": [], "followingUserIds": [], "joinedCircleIds": ["medical", "tech", "business"]],
    ]

    private func seedUsers() async throws {
        for user in dummyUsers {
            guard let id = user["id"] as? String else { continue }
            try await db.collection("users").document(id).setData(user)
        }
    }

    // MARK: - Circles

    private func seedCircles() async throws {
        let circles: [[String: Any]] = [
            [
                "id": "circle_tech", "name": "Tech", "circleDescription": "Software, hardware, AI, and everything technology.",
                "iconName": "desktopcomputer", "category": "Tech",
                "creatorId": NSNull(), "adminIds": [], "memberIds": dummyUsers.compactMap { $0["id"] as? String },
                "followerCount": 5200, "isPromoted": true, "inviteCode": NSNull(),
                "isPublic": true, "createdAt": Timestamp()
            ],
            [
                "id": "circle_medical", "name": "Medical", "circleDescription": "Health questions, doctor recommendations, and wellness tips.",
                "iconName": "cross.case.fill", "category": "Medical",
                "creatorId": NSNull(), "adminIds": [], "memberIds": dummyUsers.compactMap { $0["id"] as? String },
                "followerCount": 3800, "isPromoted": true, "inviteCode": NSNull(),
                "isPublic": true, "createdAt": Timestamp()
            ],
            [
                "id": "circle_legal", "name": "Legal", "circleDescription": "Legal advice, attorney referrals, and know your rights.",
                "iconName": "scalemass.fill", "category": "Legal",
                "creatorId": NSNull(), "adminIds": [], "memberIds": dummyUsers.compactMap { $0["id"] as? String },
                "followerCount": 2900, "isPromoted": true, "inviteCode": NSNull(),
                "isPublic": true, "createdAt": Timestamp()
            ],
            [
                "id": "circle_business", "name": "Business", "circleDescription": "Entrepreneurship, freelancing, careers, and professional networking.",
                "iconName": "briefcase.fill", "category": "Business",
                "creatorId": NSNull(), "adminIds": [], "memberIds": dummyUsers.compactMap { $0["id"] as? String },
                "followerCount": 4100, "isPromoted": true, "inviteCode": NSNull(),
                "isPublic": true, "createdAt": Timestamp()
            ],
            [
                "id": "circle_uic_msa", "name": "UIC MSA", "circleDescription": "University of Illinois Chicago Muslim Student Association.",
                "iconName": "building.columns.fill", "category": "",
                "creatorId": "seed_user_1", "adminIds": ["seed_user_1"],
                "memberIds": ["seed_user_1", "seed_user_2", "seed_user_3"],
                "followerCount": 340, "isPromoted": false, "inviteCode": NSNull(),
                "isPublic": true, "createdAt": Timestamp()
            ],
            [
                "id": "circle_rogers_park", "name": "Rogers Park Neighbors", "circleDescription": "Neighbors helping neighbors in Rogers Park, Chicago.",
                "iconName": "house.and.flag.fill", "category": "",
                "creatorId": "seed_user_2", "adminIds": ["seed_user_2"],
                "memberIds": ["seed_user_1", "seed_user_2"],
                "followerCount": 180, "isPromoted": false, "inviteCode": NSNull(),
                "isPublic": true, "createdAt": Timestamp()
            ],
        ]

        for circle in circles {
            guard let id = circle["id"] as? String else { continue }
            try await db.collection("circles").document(id).setData(circle)
        }
    }

    // MARK: - Posts (5 per promoted circle = 20 total)

    private func seedPosts() async throws {
        let postsData: [(circleName: String, title: String, body: String, authorIdx: Int)] = [
            ("Tech", "Best laptop for CS students in 2026?", "Starting CS program this fall. Budget is around $1200. MacBook Air M3 or ThinkPad X1?", 0),
            ("Tech", "Anyone using Swift 6 concurrency?", "Migrating our codebase to strict concurrency. The @Sendable requirements are intense. Tips?", 1),
            ("Tech", "Free Python bootcamp starting next week", "Found this great free resource. 12-week program, project-based. Link in comments.", 3),
            ("Tech", "Help with home network setup", "Just got a new router. Need advice on mesh WiFi vs range extenders for a 2-story house.", 4),
            ("Tech", "React vs SwiftUI for side projects?", "Want to build a community app. Should I go web-first with React or native with SwiftUI?", 2),

            ("Medical", "Recommend a good dentist?", "Haven't been in 2 years. Looking for a gentle dentist near downtown Houston who takes Blue Cross.", 1),
            ("Medical", "Child keeps getting ear infections", "My 3yo has had 4 ear infections this year. Is this normal? When should I push for tubes?", 2),
            ("Medical", "Mental health resources for students", "As a grad student, I'm struggling. Are there affordable therapy options?", 0),
            ("Medical", "Dermatologist for eczema?", "Tried everything OTC. Need a specialist. Anyone in the DFW area have a recommendation?", 3),
            ("Medical", "Fasting with diabetes — safe?", "Type 2 diabetic. Ramadan is coming. Looking for a doctor who can help me plan safe fasting.", 4),

            ("Legal", "Need help with immigration paperwork", "Looking for an attorney who can help with H1B to green card process. Any recommendations?", 0),
            ("Legal", "Landlord refusing to return deposit", "Moved out 45 days ago, place was spotless. Landlord ghosting me. What are my options?", 1),
            ("Legal", "Small business LLC formation help", "Starting a food truck. Need guidance on LLC formation in Texas. Pro bono or low cost preferred.", 2),
            ("Legal", "Traffic ticket — worth fighting?", "Got a speeding ticket on I-90. 15 over. Anyone know a good traffic attorney in Chicago?", 3),
            ("Legal", "Understanding tenant rights in CA", "New renter in LA. What are the key things I should know about my rights as a tenant?", 4),

            ("Business", "Need a website built for my business", "Small catering business. Need a simple website with menu, about us, and contact form. Budget ~$500.", 3),
            ("Business", "Tax filing help for freelancers", "First year freelancing. 1099 income. No idea what I'm doing with taxes. Anyone a CPA?", 0),
            ("Business", "Resume review — tech industry", "Applying for software engineering roles. Would love a second pair of eyes on my resume.", 1),
            ("Business", "How to price freelance graphic design?", "Getting my first clients but not sure what to charge. Hourly vs project? Any freelancers here?", 4),
            ("Business", "Networking event downtown this Friday", "Tech professionals meetup at WeWork. Free food and great connections. DM for details.", 2),
        ]

        for (i, post) in postsData.enumerated() {
            let user = dummyUsers[post.authorIdx]
            let id = "seed_post_\(i)"
            let hoursAgo = Double(i) * 2.5
            let timestamp = Date().addingTimeInterval(-hoursAgo * 3600)
            let circleId = "circle_\(post.circleName.lowercased())"

            let data: [String: Any] = [
                "id": id,
                "circleId": circleId,
                "circleName": post.circleName,
                "authorId": user["id"] as? String ?? "",
                "authorName": user["name"] as? String ?? "",
                "authorProfilePic": user["profilePictureURL"] as Any,
                "title": post.title,
                "body": post.body,
                "imageURL": NSNull(),
                "likes": i % 3 == 0 ? ["seed_user_1", "seed_user_2"] : (i % 2 == 0 ? ["seed_user_3"] : []),
                "commentCount": i % 4,
                "shareCount": i % 3,
                "timestamp": Timestamp(date: timestamp)
            ]
            try await db.collection("posts").document(id).setData(data)
        }
    }

    // MARK: - Help cards (6 per circle = 24 total, mix of urgent and normal)

    private func seedHelpCards() async throws {
        let cardsData: [(title: String, desc: String, skill: String, urgency: String, isRemote: Bool, authorIdx: Int, circleKey: String)] = [
            // Tech (6 cards: 3 urgent, 3 normal)
            ("My laptop won't boot — SOS", "MacBook Pro showing folder icon with question mark. Genius Bar is booked for 3 days. Please help!", "Tech Help", "Urgent Today", false, 2, "tech"),
            ("Website crashed — need help ASAP", "My WordPress site is showing 500 error. I'm losing customers every hour. Can anyone SSH in and check?", "Tech Help", "Urgent Today", false, 4, "tech"),
            ("WiFi died before my interview tomorrow", "Router completely stopped working. Have a remote interview at 9am. Need someone who can troubleshoot tonight.", "Tech Help", "Urgent Today", false, 0, "tech"),
            ("Help setting up a home server", "Want to self-host a Nextcloud instance. Need someone who knows Linux. Happy to pay for time.", "Tech Help", "Normal", true, 1, "tech"),
            ("Python tutor for my daughter", "8th grader interested in coding. Looking for someone patient. Once a week, 1 hour sessions.", "Tutoring", "Normal", true, 3, "tech"),
            ("Need help migrating from Heroku", "Moving my Node.js app to a VPS. Comfortable with code but unfamiliar with server admin.", "Tech Help", "Normal", true, 0, "tech"),

            // Medical (6 cards: 2 urgent, 4 normal)
            ("Need medical interpreter — Arabic", "Elderly parent has appointment Friday. Doctor doesn't speak Arabic. Critical lab results to discuss.", "Translation", "Urgent Today", false, 0, "medical"),
            ("Grocery run — recovering from surgery", "Can't drive for 2 more weeks post knee surgery. Need someone to pick up groceries. I'll Venmo + tip.", "Groceries", "Urgent Today", false, 4, "medical"),
            ("Recommend a pediatrician in Houston?", "Just moved here. Need a good pediatrician for my toddler. Prefer female doctor.", "Medical", "Normal", false, 1, "medical"),
            ("Can someone explain health insurance?", "Just turned 26, off parents' plan. Marketplace is so confusing. A 15 min call would save me hours.", "Medical", "Normal", true, 3, "medical"),
            ("Physical therapist recommendation?", "Recovering from ACL surgery. Need a PT who takes Aetna in the Chicago area.", "Medical", "Normal", false, 2, "medical"),
            ("Ride to chemo appointment Wednesday", "My car is in the shop and Uber is too expensive for the 45 min drive. Can anyone help?", "Rides", "Normal", false, 4, "medical"),

            // Legal (6 cards: 2 urgent, 4 normal)
            ("Need immigration lawyer ASAP", "H1B transfer deadline is in 5 days. Current attorney ghosted me. Need someone who can file an emergency petition.", "Legal", "Urgent Today", true, 3, "legal"),
            ("Eviction notice — is this legal?", "Landlord taped an eviction notice on my door for being 3 days late on rent. No prior warning. Is this enforceable?", "Legal", "Urgent Today", false, 0, "legal"),
            ("Legal question about lease breaking", "Job transfer to another state. 6 months left on lease. What penalties should I expect?", "Legal", "Normal", true, 4, "legal"),
            ("Help understanding custody agreement", "Going through a divorce. The proposed agreement seems unfair. Need someone to review before I sign.", "Legal", "Normal", true, 2, "legal"),
            ("Small claims court advice", "Contractor took $3000 and disappeared mid-project. What's the process for small claims court in IL?", "Legal", "Normal", false, 1, "legal"),
            ("Starting an LLC — Texas vs Delaware?", "Launching my e-commerce business. Heard Delaware is better for LLCs. Anyone with experience?", "Legal", "Normal", true, 3, "legal"),

            // Business (6 cards: 2 urgent, 4 normal)
            ("Help with tax filing — deadline tomorrow", "First year freelancing. 1099 income. Extension deadline is tomorrow and I haven't filed. Need a CPA urgently!", "Other", "Urgent Today", true, 1, "business"),
            ("Need photographer for event TONIGHT", "Our event photographer cancelled last minute. Corporate dinner, 50 people. 6pm-9pm in NYC. Will pay premium.", "Other", "Urgent Today", false, 4, "business"),
            ("Resume review for FAANG applications", "Applying to Google and Meta next week. Need someone in tech to review my resume. Can do Zoom.", "Job Referrals", "Normal", true, 0, "business"),
            ("Need a photographer for small nikah", "Intimate gathering, 30 people. Looking for someone available March 15th in NYC area.", "Other", "Normal", false, 4, "business"),
            ("Babysitter for Friday evening", "Date night with spouse. Need someone responsible for our 6yo. 6pm-10pm. West Loop area.", "Childcare", "Normal", false, 2, "business"),
            ("Freelance graphic designer needed", "Need a logo and brand kit for my food truck business. Budget is $300-500. Portfolio required.", "Other", "Normal", true, 3, "business"),
        ]

        for (i, card) in cardsData.enumerated() {
            let user = dummyUsers[card.authorIdx]
            let id = "seed_card_\(i)"
            let hoursAgo = Double(i) * 1.2
            let timestamp = Date().addingTimeInterval(-hoursAgo * 3600)
            let userLat = user["latitude"] as? Double ?? 41.8781
            let userLng = user["longitude"] as? Double ?? -87.6298

            var data: [String: Any] = [
                "id": id,
                "authorId": user["id"] as? String ?? "",
                "authorName": user["name"] as? String ?? "",
                "authorProfilePic": user["profilePictureURL"] as Any,
                "title": card.title,
                "cardDescription": card.desc,
                "skill": card.skill,
                "urgency": card.urgency,
                "isRemote": card.isRemote,
                "latitude": card.isRemote ? NSNull() : userLat,
                "longitude": card.isRemote ? NSNull() : userLng,
                "locationName": user["location"] as Any,
                "circleId": "circle_\(card.circleKey)",
                "status": "open",
                "swipedRightUserIds": [],
                "swipedLeftUserIds": [],
                "timestamp": Timestamp(date: timestamp)
            ]

            if card.urgency == "Urgent Today" {
                let endOfDay = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: Date())!
                data["expiresAt"] = Timestamp(date: endOfDay)
            } else {
                data["expiresAt"] = NSNull()
            }

            try await db.collection("helpCards").document(id).setData(data)
        }
    }
}
