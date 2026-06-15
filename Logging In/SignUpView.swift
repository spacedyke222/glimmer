import SwiftUI
import SwiftData

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // MARK: - State
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var mantra = ""
    @State private var birthday = Date()
    @State private var height: Int? = nil
    @State private var weight: Int? = nil
    @State private var primaryActivity: String? = nil
    @State private var gender: String? = nil
    @State private var biologicalSex: String? = nil

    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""

    // MARK: - Options
    let activities = ["Run", "Walk", "Bike", "Strength"]
    let genders = ["Man", "Woman", "Non-binary"]
    let biologicalSexes = ["Male", "Female"]
    let heights = Array(48...84)      // 4ft to 7ft
    let weights = Array(80...300)     // 80lb to 300lb


    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.indigo]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    Text("Create Account")
                        .font(.custom("Motterdam", size: 36))
                        .foregroundColor(Color.purple)
                        .shadow(radius: 4)
                        .padding(.top, 40)

                    // Signup Card
                    VStack(spacing: 16) {
                        TextField("", text: $name, prompt: Text("Name").foregroundColor(.black.opacity(0.4)))
                            .padding().background(Color.white).cornerRadius(12).foregroundColor(.black)

                        TextField("", text: $email, prompt: Text("Email").foregroundColor(.black.opacity(0.4)))
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled(true)
                            .textInputAutocapitalization(.never)
                            .padding().background(Color.white).cornerRadius(12).foregroundColor(.black)

                        SecureField("", text: $password, prompt: Text("Password").foregroundColor(.black.opacity(0.4)))
                            .padding().background(Color.white).cornerRadius(12).foregroundColor(.black)
                        
                        DatePicker("Birthday", selection: $birthday, displayedComponents: .date)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)

                        TextField("", text: $mantra, prompt: Text("Your Personal Mantra").foregroundColor(.black.opacity(0.4)))
                            .padding().background(Color.white).cornerRadius(12).foregroundColor(.black)

                        HStack {
                            Menu {
                                ForEach(heights, id: \.self) { h in
                                    Button("\(h) in") { height = h }
                                }
                            } label: {
                                Text(height != nil ? "\(height!) in" : "Select Height")
                                    .foregroundColor(height != nil ? .black : .gray)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.white)
                                    .cornerRadius(12)
                            }

                            Menu {
                                ForEach(weights, id: \.self) { w in
                                    Button("\(w) lb") { weight = w }
                                }
                            } label: {
                                Text(weight != nil ? "\(weight!) lb" : "Select Weight")
                                    .foregroundColor(weight != nil ? .black : .gray)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.white)
                                    .cornerRadius(12)
                            }
                        }

                        Menu {
                            ForEach(activities, id: \.self) { a in
                                Button(a) { primaryActivity = a }
                            }
                        } label: {
                            Text(primaryActivity ?? "Select Primary Activity")
                                .foregroundColor(primaryActivity != nil ? .black : .gray)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.white)
                                .cornerRadius(12)
                        }

                        HStack {
                            Menu {
                                ForEach(genders, id: \.self) { g in
                                    Button(g) { gender = g }
                                }
                            } label: {
                                Text(gender ?? "Select Gender")
                                    .foregroundColor(gender != nil ? .black : .gray)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.white)
                                    .cornerRadius(12)
                            }

                            Menu {
                                ForEach(biologicalSexes, id: \.self) { s in
                                    Button(s) { biologicalSex = s }
                                }
                            } label: {
                                Text(biologicalSex ?? "Select Biological Sex")
                                    .foregroundColor(biologicalSex != nil ? .black : .gray)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.white)
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding(30)
                    .background(Color.white.opacity(0.85))
                    .cornerRadius(28)
                    .shadow(color: .black.opacity(0.1), radius: 12, y: 4)
                    .padding(.horizontal, 20)

                    // Signup Button
                    Button(action: signup) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.pink, Color.orange],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: .black.opacity(0.2), radius: 6, y: 3)

                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Sign Up")
                                    .foregroundColor(.white)
                                    .font(.system(size: 20, weight: .bold))
                            }
                        }
                        .frame(width: 300, height: 55)
                    }

                    if showError {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.top, 4)
                    }

                    Spacer(minLength: 40)
                }
            }
        }
    }

    func signup() {
        guard !name.isEmpty,
              !email.isEmpty,
              !password.isEmpty,
              !mantra.isEmpty,
              let height = height,
              let weight = weight,
              let primaryActivity = primaryActivity,
              let gender = gender,
              let biologicalSex = biologicalSex else {
            showError = true
            errorMessage = "Please fill in all fields"
            return
        }

        showError = false
        isLoading = true

        let newProfile = UserProfile(
            email: email,
            name: name,
            height: height,
            weight: weight,
            mantra: mantra,
            primaryActivity: primaryActivity,
            gender: gender,
            biologicalSex: biologicalSex,
            birthday: birthday
        )

        modelContext.insert(newProfile)
        do {
            try modelContext.save()

            // Save password in Keychain
            let success = KeychainManager.savePassword(password, for: email)
            if !success {
                print("❌ Failed to save password in Keychain")
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isLoading = false
                dismiss() // back to login
            }

        } catch {
            print("Failed to save profile: \(error)")
            showError = true
            errorMessage = "Failed to save profile"
            isLoading = false
        }
    }

}


#Preview{
    SignUpView()
}
