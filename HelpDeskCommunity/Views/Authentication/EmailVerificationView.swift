//
//  EmailVerificationView.swift
//  HelpDeskCommunity
//
//  Created on Feb 12, 2026.
//

import SwiftUI

struct EmailVerificationView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var timer: Timer?
    @State private var canResend = false
    @State private var countdown = 60
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Header
            VStack(spacing: 16) {
                Image(systemName: "envelope.badge.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Verify Your Email")
                    .font(.title)
                    .fontWeight(.bold)
                
                if let email = authViewModel.emailToVerify {
                    Text("We've sent a verification link to:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(email)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            }
            
            // Instructions
            VStack(alignment: .leading, spacing: 12) {
                Text("Please check your email and:")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    InstructionItem(text: "Open the verification email")
                    InstructionItem(text: "Click on the verification link")
                    InstructionItem(text: "Return to the app to continue")
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Actions
            VStack(spacing: 16) {
                Button(action: {
                    Task {
                        await authViewModel.checkEmailVerification()
                    }
                }) {
                    Text("I've Verified My Email")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    Task {
                        await authViewModel.resendVerificationEmail()
                        startCountdown()
                    }
                }) {
                    HStack {
                        Text("Resend Email")
                        if !canResend {
                            Text("(\(countdown)s)")
                                .fontWeight(.regular)
                        }
                    }
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canResend ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                    .foregroundColor(canResend ? .blue : .gray)
                    .cornerRadius(10)
                }
                .disabled(!canResend)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .onAppear {
            startCountdown()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startCountdown() {
        canResend = false
        countdown = 60
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if countdown > 0 {
                countdown -= 1
            } else {
                canResend = true
                timer?.invalidate()
            }
        }
    }
}

struct InstructionItem: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "circle.fill")
                .foregroundColor(.blue)
                .font(.system(size: 8))
                .padding(.top, 6)
            
            Text(text)
                .font(.body)
        }
    }
}
