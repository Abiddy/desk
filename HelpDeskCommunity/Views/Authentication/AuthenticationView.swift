//
//  AuthenticationView.swift
//  HelpDeskCommunity
//
//  Created on Feb 12, 2026.
//

import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isLoginMode = true
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Logo/Header
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Text("Help Desk Community")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text(isLoginMode ? "Welcome back" : "Create your account")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // Form
                    VStack(spacing: 16) {
                        if !isLoginMode {
                            TextField("Full Name", text: $name)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.words)
                        }
                        
                        TextField("Email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        if !isLoginMode {
                            SecureField("Confirm Password", text: $confirmPassword)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal)
                        }
                        
                        Button(action: handleAuth) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                }
                                Text(isLoginMode ? "Sign In" : "Sign Up")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFormValid ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(!isFormValid || isLoading)
                    }
                    .padding(.horizontal)
                    
                    // Toggle mode
                    Button(action: {
                        isLoginMode.toggle()
                        errorMessage = nil
                    }) {
                        Text(isLoginMode ? "Don't have an account? Sign Up" : "Already have an account? Sign In")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
        .alert("Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
    }
    
    private var isFormValid: Bool {
        if isLoginMode {
            return !email.isEmpty && !password.isEmpty && email.contains("@")
        } else {
            return !name.isEmpty && !email.isEmpty && !password.isEmpty && 
                   password == confirmPassword && password.count >= 6 && email.contains("@")
        }
    }
    
    private func handleAuth() {
        errorMessage = nil
        isLoading = true
        
        Task {
            if isLoginMode {
                await authViewModel.signIn(email: email, password: password)
                if let error = authViewModel.authService.errorMessage {
                    errorMessage = error
                    showAlert = true
                }
            } else {
                await authViewModel.signUp(email: email, password: password, name: name)
                if let error = authViewModel.authService.errorMessage {
                    errorMessage = error
                    showAlert = true
                }
            }
            
            isLoading = false
        }
    }
}
