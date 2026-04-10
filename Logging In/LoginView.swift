import SwiftUI
import SwiftData

struct LoginView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.name) private var profiles: [UserProfile]

    @State private var email = ""
    @State private var password = ""
    @State private var isSecure = true
    @State private var isLoading = false
    @State private var navigateToSignup = false
    @State private var loginError = ""
    @State private var loggedInProfile: UserProfile? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color(red: 204/255, green: 204/255, blue: 255/255).opacity(0.6),
                                                Color(red: 41/255, green: 41/255, blue: 102/255)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 40) {
                    Text("Glimmer")
                        .font(.custom("Motterdam", size: 40))
                        .foregroundColor(Color(red: 204/255, green: 204/255, blue: 255/255))
                        .shadow(radius: 4)
                        .padding(.top, 40)

                    VStack(spacing: 20) {
                        TextField("Email", text: $email, prompt: Text("Email").foregroundColor(.black.opacity(0.4)))
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled(true)
                            .textInputAutocapitalization(.never)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .foregroundColor(.black)

                        HStack {
                            if isSecure {
                                SecureField("••••••••", text: $password, prompt: Text("Password").foregroundColor(.black.opacity(0.4)))
                                    .foregroundColor(.black)
                            } else {
                                TextField("Password", text: $password)
                                    .foregroundColor(.black)
                            }

                            Button(action: { isSecure.toggle() }) {
                                Image(systemName: isSecure ? "eye" : "eye.slash").foregroundColor(.black.opacity(0.4))
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)

                        Button(action: login) {
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
                                    Text("Log In")
                                        .foregroundColor(.white)
                                        .font(.system(size: 20, weight: .bold))
                                }
                            }
                            .frame(height: 55)
                        }

                        if !loginError.isEmpty {
                            Text(loginError)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                    .padding(30)
                    .background(Color.white.opacity(0.85))
                    .cornerRadius(28)
                    .shadow(color: .black.opacity(0.1), radius: 12, y: 4)
                    .padding(.horizontal, 20)

                    Spacer()

                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .foregroundColor(.white.opacity(0.9))

                        Button("Sign Up") {
                            navigateToSignup = true
                        }
                        .foregroundColor(Color.pink)
                        .fontWeight(.bold)
                        .navigationDestination(isPresented: $navigateToSignup) {
                            SignUpView()
                        }
                    }

                    // Navigate to dashboard after login
                    .navigationDestination(isPresented: Binding(
                        get: { loggedInProfile != nil },
                        set: { newValue in
                            if !newValue { loggedInProfile = nil }
                        }
                    )) {
                        if let profile = loggedInProfile {
                            DashboardView(profile: profile)
                        }
                    }

                    Spacer(minLength: 40)
                }
            }
        }
    }

    func login() {
        guard !email.isEmpty else { loginError = "Enter email"; return }
        isLoading = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoading = false

            guard let profile = profiles.first(where: { $0.email.lowercased() == email.lowercased() }) else {
                loginError = "No profile found with that email"
                return
            }

            guard let storedPassword = KeychainManager.getPassword(for: email) else {
                loginError = "No password found for this account"
                return
            }

            if storedPassword == password {
                loggedInProfile = profile
                loginError = ""
            } else {
                loginError = "Incorrect password"
            }
        }
    }

}


#Preview{
    LoginView()
}
