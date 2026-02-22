//
//  AuthViewModel.swift
//  HelpDeskCommunity
//
//  Created on Feb 12, 2026.
//

import Foundation
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isSignedIn = false
    @Published var showNDA = false
    @Published var showEmailVerification = false
    @Published var emailToVerify: String?
    
    let authService = AuthService()
    private let userDefaults = UserDefaults.standard
    private let ndaAcceptedKey = "ndaAccepted"
    
    init() {
        checkNDAStatus()
        checkAuthStatus()
    }
    
    // MARK: - NDA Management
    func checkNDAStatus() {
        if !userDefaults.bool(forKey: ndaAcceptedKey) {
            showNDA = true
        }
    }
    
    func acceptNDA() {
        userDefaults.set(true, forKey: ndaAcceptedKey)
        showNDA = false
    }
    
    // MARK: - Authentication
    func signUp(email: String, password: String, name: String) async {
        do {
            try await authService.signUp(email: email, password: password, name: name)
            emailToVerify = email
            showEmailVerification = true
        } catch {
            print("Sign up error: \(error.localizedDescription)")
        }
    }
    
    func signIn(email: String, password: String) async {
        do {
            try await authService.signIn(email: email, password: password)
            isSignedIn = authService.isAuthenticated
        } catch {
            print("Sign in error: \(error.localizedDescription)")
        }
    }
    
    func signOut() {
        do {
            try authService.signOut()
            isSignedIn = false
        } catch {
            print("Sign out error: \(error.localizedDescription)")
        }
    }
    
    func resendVerificationEmail() async {
        do {
            try await authService.resendVerificationEmail()
        } catch {
            print("Resend verification error: \(error.localizedDescription)")
        }
    }
    
    func checkEmailVerification() async {
        do {
            let isVerified = try await authService.checkEmailVerification()
            if isVerified {
                await authService.loadUserData(userId: authService.currentUser?.id ?? "")
                isSignedIn = true
                showEmailVerification = false
            }
        } catch {
            print("Check verification error: \(error.localizedDescription)")
        }
    }
    
    private func checkAuthStatus() {
        isSignedIn = authService.isAuthenticated
    }
}
