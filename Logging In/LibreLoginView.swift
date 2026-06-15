//
//  LibreLoginView.swift
//  TRunD (Glimmer)
//
//  Sign-in sheet for Abbott's LibreLinkUp. Hands credentials to LibreService,
//  which stores them in the Keychain. Presented from SettingsView.
//

import SwiftUI

struct LibreLoginView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var libreAuth = LibreAuthState.shared

    @State private var email = ""
    @State private var password = ""
    @State private var isSecure = true
    @State private var isLoading = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 204/255, green: 204/255, blue: 255/255).opacity(0.6),
                    Color(red: 41/255, green: 41/255, blue: 102/255)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    header
                    if libreAuth.isLoggedIn {
                        connectedCard
                    } else {
                        loginCard
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 40)
            }
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: 34))
                .foregroundColor(.white)

            Text("Connect Libre")
                .font(.custom("Motterdam", size: 36))
                .foregroundColor(Color(red: 204/255, green: 204/255, blue: 255/255))
                .shadow(radius: 4)

            Text("Sign in with your LibreLinkUp account — the follower app linked to your Libre 3+ sensor.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.85))
                .padding(.horizontal, 12)
        }
        .padding(.top, 12)
    }

    private var loginCard: some View {
        VStack(spacing: 20) {
            TextField("Email", text: $email,
                      prompt: Text("LibreLinkUp email").foregroundColor(.black.opacity(0.4)))
                .keyboardType(.emailAddress)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .foregroundColor(.black)

            HStack {
                if isSecure {
                    SecureField("••••••••", text: $password,
                                prompt: Text("Password").foregroundColor(.black.opacity(0.4)))
                        .foregroundColor(.black)
                } else {
                    TextField("Password", text: $password)
                        .foregroundColor(.black)
                }
                Button(action: { isSecure.toggle() }) {
                    Image(systemName: isSecure ? "eye" : "eye.slash")
                        .foregroundColor(.black.opacity(0.4))
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)

            Button(action: connect) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 255/255, green: 60/255, blue: 150/255),
                                         Color(red: 255/255, green: 111/255, blue: 60/255)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .black.opacity(0.2), radius: 6, y: 3)

                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Connect")
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .bold))
                    }
                }
                .frame(height: 55)
            }
            .disabled(isLoading)

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }

            Button("Cancel") { dismiss() }
                .foregroundColor(.black.opacity(0.5))
                .font(.subheadline)
        }
        .padding(28)
        .background(Color.white.opacity(0.9))
        .cornerRadius(28)
        .shadow(color: .black.opacity(0.1), radius: 12, y: 4)
    }

    private var connectedCard: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 44))
                .foregroundColor(.green)

            Text("Libre sensor connected")
                .font(.headline)
                .foregroundColor(.black)

            Text("Glimmer is reading glucose from your LibreLinkUp account.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundColor(.black.opacity(0.6))

            Button(action: disconnect) {
                Text("Disconnect")
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.red.opacity(0.85))
                    .cornerRadius(14)
            }

            Button("Done") { dismiss() }
                .foregroundColor(.black.opacity(0.5))
                .font(.subheadline)
        }
        .padding(28)
        .background(Color.white.opacity(0.9))
        .cornerRadius(28)
        .shadow(color: .black.opacity(0.1), radius: 12, y: 4)
    }

    // MARK: - Actions

    private func connect() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Enter your LibreLinkUp email and password."
            return
        }
        isLoading = true
        errorMessage = ""
        Task {
            do {
                try await LibreService.shared.logIn(email: email, password: password)
                isLoading = false
                dismiss()
            } catch {
                isLoading = false
                errorMessage = (error as? LibreError)?.errorDescription
                    ?? error.localizedDescription
            }
        }
    }

    private func disconnect() {
        Task { await LibreService.shared.logOut() }
    }
}

#Preview {
    LibreLoginView()
}
