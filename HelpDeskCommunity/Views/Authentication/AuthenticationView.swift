//
//  AuthenticationView.swift
//  Helpdecks
//

import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showSignUp = false
    @State private var showSignUpFromSignIn = false

    private let gridIcons: [(String, Color)] = [
        ("hands.sparkles.fill", .blue),
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
        NavigationStack {
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
            VStack(spacing: 16) {
                Image("LandingLogo", bundle: .module)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)

                VStack(spacing: 8) {
                    Text("HelpDesk")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundColor(.black)

                    Text("Help People in Your Community")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 32)

            // Buttons
            VStack(spacing: 12) {
                Button {
                    showSignUp = true
                } label: {
                    Text("Get Started")
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }

                NavigationLink(destination: SignInPageView(showSignUp: $showSignUpFromSignIn)) {
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
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.secondary)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(Color.white)
        }
        .sheet(isPresented: $showSignUp) {
            AuthFormSheet(isLoginMode: false)
        }
        .onChange(of: showSignUpFromSignIn) { _, newValue in
            if newValue {
                showSignUp = true
                showSignUpFromSignIn = false
            }
        }
    }
}

// MARK: - Sign-in as full page (not sheet)

struct SignInPageView: View {
    @Binding var showSignUp: Bool
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && email.contains("@")
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Color.black
                    .frame(minHeight: 180)
                    .frame(maxWidth: .infinity)

                Text("Help people in your community")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .frame(maxWidth: .infinity)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email Address")
                                .font(.system(size: 13))
                                .foregroundColor(.black)

                            TextField("random.username@gmail.com", text: $email)
                                .textFieldStyle(.plain)
                                .font(.system(size: 15))
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .padding(12)
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                                .cornerRadius(10)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Password")
                                .font(.system(size: 13))
                                .foregroundColor(.black)

                            SecureField("Enter your password", text: $password)
                                .textFieldStyle(.plain)
                                .font(.system(size: 15))
                                .padding(12)
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                                .cornerRadius(10)

                            HStack {
                                Spacer()
                                Button("Reset Password") { }
                                    .font(.system(size: 13))
                                    .foregroundColor(.blue)
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                            .padding(.horizontal, 24)
                    }

                    Button {
                        handleAuth()
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView().tint(.white)
                            }
                            Text("Login")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isFormValid ? Color.black : Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(!isFormValid || isLoading)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                    HStack(spacing: 4) {
                        Text("New to HelpDesk?")
                            .font(.system(size: 13))
                            .foregroundColor(Color(.systemGray))
                        Button("Sign Up") {
                            showSignUp = true
                            dismiss()
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.blue)
                        .underline()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 24)
                    .padding(.bottom, 80)
                }
            }
            .scrollIndicators(.hidden)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear.frame(height: 1)
            }
            .background(Color.white)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 24,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 24
                )
            )
            .offset(y: -20)
        }
        .background(Color.black)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
    }

    private func handleAuth() {
        errorMessage = nil
        isLoading = true
        Task {
            await authViewModel.signIn(email: email, password: password)
            if let error = authViewModel.authService.errorMessage {
                errorMessage = error
            }
            isLoading = false
        }
    }
}

// MARK: - Auth form (shared for sign-in and sign-up)

struct AuthFormSheet: View {
    let isLoginMode: Bool
    var onSwitchToSignUp: (() -> Void)? = nil
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
            if isLoginMode {
                signInView
            } else {
                signUpView
            }
        }
    }

    private var signInView: some View {
        VStack(spacing: 0) {
            // Black header with tagline
            ZStack {
                Color.black
                    .frame(minHeight: 180)
                    .frame(maxWidth: .infinity)

                Text("Help people in your community")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .frame(maxWidth: .infinity)

            // White card with form
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email Address")
                                .font(.system(size: 13))
                                .foregroundColor(.black)

                            TextField("random.username@gmail.com", text: $email)
                                .textFieldStyle(.plain)
                                .font(.system(size: 15))
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .padding(12)
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                                .cornerRadius(10)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Password")
                                .font(.system(size: 13))
                                .foregroundColor(.black)

                            SecureField("Enter your password", text: $password)
                                .textFieldStyle(.plain)
                                .font(.system(size: 15))
                                .padding(12)
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                                .cornerRadius(10)

                            HStack {
                                Spacer()
                                Button("Reset Password") { }
                                    .font(.system(size: 13))
                                    .foregroundColor(.blue)
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                            .padding(.horizontal, 24)
                    }

                    Button {
                        handleAuth()
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView().tint(.white)
                            }
                            Text("Login")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isFormValid ? Color.black : Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(!isFormValid || isLoading)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                    HStack(spacing: 4) {
                        Text("New to HelpDesk?")
                            .font(.system(size: 13))
                            .foregroundColor(Color(.systemGray))
                        Button("Sign Up") {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onSwitchToSignUp?()
                            }
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.blue)
                        .underline()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 24)
                    .padding(.bottom, 80)
                }
            }
            .scrollIndicators(.hidden)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear.frame(height: 1)
            }
            .background(Color.white)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 24,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 24
                )
            )
            .offset(y: -20)
        }
        .background(Color.black)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }

    private var signUpView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Create your account")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 20)

                VStack(spacing: 14) {
                    TextField("Full Name", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.words)

                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()

                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)

                    SecureField("Confirm Password", text: $confirmPassword)
                        .textFieldStyle(.roundedBorder)
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
                        Text("Sign Up")
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
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
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
