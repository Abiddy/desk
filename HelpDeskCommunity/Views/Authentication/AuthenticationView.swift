//
//  AuthenticationView.swift
//  Helpdecks
//

import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showSignUp = false
    @State private var showSignIn = false

    private let gridIcons: [(String, Color)] = [
        ("hands.sparkles.fill", .purple),
        ("heart.circle.fill", .pink),
        ("person.3.fill", .blue),
        ("lightbulb.fill", .yellow),
        ("graduationcap.fill", .green),
        ("stethoscope", .red),
        ("briefcase.fill", .orange),
        ("wrench.and.screwdriver.fill", .teal),
        ("car.fill", .indigo),
        ("book.fill", .mint),
        ("house.fill", .brown),
        ("globe.americas.fill", .cyan),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Colorful icon grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                ForEach(0..<12, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 16)
                        .fill(gridIcons[i].1.opacity(0.15))
                        .frame(height: 80)
                        .overlay(
                            Image(systemName: gridIcons[i].0)
                                .font(.title)
                                .foregroundColor(gridIcons[i].1)
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)

            Spacer()

            // Branding
            VStack(spacing: 8) {
                Text("Helpdecks")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundColor(.black)

                Text("Your community, one card at a time.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 32)

            // Buttons
            VStack(spacing: 12) {
                Button {
                    showSignUp = true
                } label: {
                    Text("Get Started")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }

                Button {
                    showSignIn = true
                } label: {
                    Text("I already have an account")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(.systemGray6))
                        .foregroundColor(.primary)
                        .cornerRadius(14)
                }
            }
            .padding(.horizontal, 24)

            // Terms
            HStack(spacing: 4) {
                Text("Terms & Conditions")
                    .underline()
                Text("·")
                Text("Privacy Policy")
                    .underline()
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(Color.white)
        .sheet(isPresented: $showSignUp) {
            AuthFormSheet(isLoginMode: false)
        }
        .sheet(isPresented: $showSignIn) {
            AuthFormSheet(isLoginMode: true)
        }
    }
}

// MARK: - Auth form (shared for sign-in and sign-up)

struct AuthFormSheet: View {
    let isLoginMode: Bool
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text(isLoginMode ? "Welcome back" : "Create your account")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top, 20)

                    VStack(spacing: 14) {
                        if !isLoginMode {
                            TextField("Full Name", text: $name)
                                .textFieldStyle(.roundedBorder)
                                .autocapitalization(.words)
                        }

                        TextField("Email", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()

                        SecureField("Password", text: $password)
                            .textFieldStyle(.roundedBorder)

                        if !isLoginMode {
                            SecureField("Confirm Password", text: $confirmPassword)
                                .textFieldStyle(.roundedBorder)
                        }
                    }

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    Button {
                        handleAuth()
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView().tint(.white)
                            }
                            Text(isLoginMode ? "Sign In" : "Sign Up")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isFormValid ? Color.blue : Color.gray.opacity(0.4))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!isFormValid || isLoading)
                }
                .padding(.horizontal, 24)
            }
            .navigationTitle(isLoginMode ? "Sign In" : "Sign Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
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
                }
            } else {
                await authViewModel.signUp(email: email, password: password, name: name)
                if let error = authViewModel.authService.errorMessage {
                    errorMessage = error
                }
            }
            isLoading = false
        }
    }
}
