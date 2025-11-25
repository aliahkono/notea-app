//
//  AuthenticationView.swift
//  Notea
//
//

import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var databaseManager: DatabaseManager
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @Environment(\.presentationMode) var presentationMode // For dismissing the view

    var body: some View {
        VStack(spacing: 20) {
            // Logo
            Image("NoteaAppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .cornerRadius(20)

            Text("Welcome to Notea")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text(isSignUp ? "Create your account" : "Sign in to continue")
                .font(.subheadline)
                .foregroundColor(.secondary)

            VStack(spacing: 15) {
                // Email field
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .onChange(of: email) { _ in
                        validateEmail()
                    }

                // Password field
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                // Sign in/up button
                Button(action: {
                    Task {
                        await handleAuthentication()
                    }
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(isSignUp ? "Sign Up" : "Sign In")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isLoading || email.isEmpty || password.isEmpty ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(isLoading || email.isEmpty || password.isEmpty)

                // Toggle between sign in and sign up
                Button(action: {
                    withAnimation {
                        isSignUp.toggle()
                    }
                }) {
                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .font(.footnote)
                        .foregroundColor(.blue)
                }

                // Continue without account
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Continue without account")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }

    private func handleAuthentication() async {
        isLoading = true

        do {
            if isSignUp {
                try await databaseManager.signUp(email: email, password: password)
            } else {
                try await databaseManager.signIn(email: email, password: password)
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }

    private func validateEmail() {
        if !email.isEmpty && !email.contains("@") {
            errorMessage = "Please enter a valid email address."
            showError = true
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(DatabaseManager.shared)
}
