//
//  AuthService.swift
//  HelpDeskCommunity
//
//  Created on Feb 12, 2026.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

// MARK: - User-friendly error messages for Firebase Auth
private func authErrorMessage(for error: Error) -> String {
    let nsError = error as NSError
    // Firebase Auth error domain
    if nsError.domain == AuthErrorDomain,
       let authErrorCode = AuthErrorCode(_bridgedNSError: nsError) {
        switch authErrorCode.code {
        case .operationNotAllowed:
            return "Email sign-up is not enabled. Enable 'Email/Password' in Firebase Console → Authentication → Sign-in method."
        case .invalidEmail:
            return "Please enter a valid email address."
        case .emailAlreadyInUse:
            return "This email is already registered. Try signing in."
        case .weakPassword:
            return "Password is too weak. Use at least 6 characters."
        case .networkError:
            return "No internet connection. Check your network and try again."
        case .tooManyRequests:
            return "Too many attempts. Please try again later."
        default:
            break
        }
    }
    // Firestore errors
    if nsError.domain == "FIRFirestoreErrorDomain" {
        return "Server error saving profile. Check that Firestore is set up and your rules allow writes."
    }
    // If Firebase returns the generic "internal error", show a helpful fallback
    if nsError.localizedDescription.contains("internal error") {
        return "Sign-up failed. Common fixes: 1) In Firebase Console, go to Authentication → Sign-in method and enable 'Email/Password'. 2) Ensure you have internet. 3) Use a valid email and a password of 6+ characters."
    }
    return nsError.localizedDescription
}

@MainActor
class AuthService: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    init() {
        checkAuthState()
    }
    
    func checkAuthState() {
        if let firebaseUser = auth.currentUser {
            Task {
                await loadUserData(userId: firebaseUser.uid)
            }
        }
    }
    
    func signUp(email: String, password: String, name: String) async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            // Create Firebase Auth user
            let result = try await auth.createUser(withEmail: email, password: password)
            
            // Send email verification
            try await result.user.sendEmailVerification()
            
            // Create user document in Firestore
            let userData: [String: Any] = [
                "id": result.user.uid,
                "email": email,
                "name": name,
                "isEmailVerified": false,
                "createdAt": Timestamp(),
                "lastSeen": Timestamp(),
                "blockedUsers": [],
                "notificationSettings": [
                    "pushEnabled": true,
                    "soundEnabled": true,
                    "groupNotificationsEnabled": true,
                    "privateMessageNotificationsEnabled": true
                ],
                "chatSettings": [
                    "readReceiptsEnabled": true,
                    "typingIndicatorsEnabled": true,
                    "lastSeenEnabled": true
                ]
            ]
            
            try await db.collection("users").document(result.user.uid).setData(userData)
            
            // Load user data
            await loadUserData(userId: result.user.uid)
        } catch {
            #if DEBUG
            print("[AuthService] SignUp error: \(error). NSError: \((error as NSError).description). Code: \((error as NSError).code), Domain: \((error as NSError).domain)")
            #endif
            errorMessage = authErrorMessage(for: error)
            throw error
        }
    }
    
    func signIn(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            
            // Check email verification
            try await result.user.reload()
            if !result.user.isEmailVerified {
                throw AuthError.emailNotVerified
            }
            
            await loadUserData(userId: result.user.uid)
            // Trust Firebase Auth: user just passed email verification check
            isAuthenticated = true
            // Keep Firestore in sync so future app launches see verified state
            try? await db.collection("users").document(result.user.uid).updateData(["isEmailVerified": true])
        } catch {
            #if DEBUG
            print("[AuthService] SignIn error: \(error). NSError: \((error as NSError).description). Code: \((error as NSError).code), Domain: \((error as NSError).domain)")
            #endif
            errorMessage = authErrorMessage(for: error)
            throw error
        }
    }
    
    func signOut() throws {
        try auth.signOut()
        currentUser = nil
        isAuthenticated = false
    }
    
    func resendVerificationEmail() async throws {
        guard let user = auth.currentUser else {
            throw AuthError.noUser
        }
        
        try await user.sendEmailVerification()
    }
    
    func checkEmailVerification() async throws -> Bool {
        guard let user = auth.currentUser else {
            throw AuthError.noUser
        }
        
        try await user.reload()
        return user.isEmailVerified
    }
    
    func loadUserData(userId: String) async {
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            
            guard let data = document.data() else {
                return
            }
            
            // Convert Firestore data to User model
            let user = User(
                id: data["id"] as? String ?? userId,
                email: data["email"] as? String ?? "",
                name: data["name"] as? String ?? "",
                profilePictureURL: data["profilePictureURL"] as? String,
                location: data["location"] as? String,
                latitude: (data["latitude"] as? Double),
                longitude: (data["longitude"] as? Double),
                isEmailVerified: data["isEmailVerified"] as? Bool ?? false,
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                lastSeen: (data["lastSeen"] as? Timestamp)?.dateValue() ?? Date(),
                blockedUsers: data["blockedUsers"] as? [String] ?? []
            )
            
            currentUser = user
            isAuthenticated = user.isEmailVerified
        } catch {
            errorMessage = "Failed to load user data: \(error.localizedDescription)"
        }
    }
    
    func updateUserProfile(name: String?, location: String?, latitude: Double?, longitude: Double?) async throws {
        guard let userId = auth.currentUser?.uid else {
            throw AuthError.noUser
        }
        
        var updateData: [String: Any] = [:]
        
        if let name = name {
            updateData["name"] = name
        }
        if let location = location {
            updateData["location"] = location
        }
        if let latitude = latitude {
            updateData["latitude"] = latitude
        }
        if let longitude = longitude {
            updateData["longitude"] = longitude
        }
        
        try await db.collection("users").document(userId).updateData(updateData)
        await loadUserData(userId: userId)
    }
}

enum AuthError: LocalizedError {
    case emailNotVerified
    case noUser
    case invalidCredentials
    
    var errorDescription: String? {
        switch self {
        case .emailNotVerified:
            return "Please verify your email address before signing in."
        case .noUser:
            return "No user is currently signed in."
        case .invalidCredentials:
            return "Invalid email or password."
        }
    }
}
