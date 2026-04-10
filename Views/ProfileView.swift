import SwiftUI
import SwiftData
import PhotosUI

struct ProfileView: View {
    @Bindable var profile: UserProfile
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var image: Image? = nil
    
    var age: Int {
        let calendar = Calendar.current
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: profile.birthday, to: now)
        return ageComponents.year ?? 0
    }

    var body: some View {
        ZStack{
            // --- Soft Periwinkle Gradient Background ---
                    LinearGradient(
                        gradient: Gradient(colors: [.white, Color.purple.opacity(0.9)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
            
            ScrollView {
                VStack(spacing: 24) {
                    
                    // --- Profile Picture ---
                    VStack(spacing: 12) {
                        ZStack {
                            if let image {
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.pink, lineWidth: 4))
                                    .shadow(radius: 4)
                            } else if let data = profile.profilePictureData, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.pink, lineWidth: 4))
                                    .shadow(radius: 4)
                            } else {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 120, height: 120)
                                    .overlay(
                                        Image(systemName: "camera.fill")
                                            .font(.largeTitle)
                                            .foregroundColor(.white)
                                    )
                            }
                        }
                        
                        // --- Change Picture Button ---
                        PhotosPicker(
                            selection: $selectedItem,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            Text("Change Picture")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(
                                    LinearGradient(
                                        colors: [Color.pink, Color.orange],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                                .shadow(radius: 3)
                        }
                        .onChange(of: selectedItem) { newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    profile.profilePictureData = data
                                    if let uiImage = UIImage(data: data) {
                                        image = Image(uiImage: uiImage)
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                    
                    // --- Profile Info ---
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Name
                        Text(profile.name)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color.indigo)
                        
                        // Email
                        HStack {
                            Image(systemName: "envelope")
                                .foregroundColor(Color.pink)
                            TextField("Email", text: $profile.email)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(Color.indigo)
                        }
                        
                        // Birthday / Age
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(Color.pink)
                            Text("Age: \(age)")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(Color.indigo)
                        }
                        
                        // Primary Sport
                        HStack {
                            Image(systemName: "figure.walk")
                                .foregroundColor(Color.pink)
                            Text("Primary Sport: \(profile.primaryActivity)")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(Color.indigo)
                        }
                        
                        // Height / Weight
                        HStack(spacing: 40) {
                            HStack {
                                Image(systemName: "ruler")
                                    .foregroundColor(Color.pink)
                                Text("Height: \(profile.height) in")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(Color.indigo)
                            }
                            
                            HStack {
                                Image(systemName: "scalemass")
                                    .foregroundColor(Color.pink)
                                Text("Weight: \(profile.weight) lbs")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(Color.indigo)
                            }
                        }
                        
                        // Personal Mantra
                        HStack {
                            Image(systemName: "bolt.fill")
                                .foregroundColor(Color.pink)
                            TextField("Personal Mantra", text: $profile.mantra)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(Color.indigo)
                        }
                        
                        Spacer()
                    }
                    .padding(30)
                    .background(
                        RoundedRectangle(cornerRadius: 25, style: .continuous)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.purple.opacity(0.9), Color.white.opacity(0.9)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.indigo.opacity(0.4), radius: 6, y: 4)
                    .padding(.horizontal)
                        )
                }
                .padding(.top, 50)
            }
            .navigationTitle("Profile")
        }
    }
}

#Preview("iPhone 15 Pro") {
    let mockProfile = UserProfile(
        email: "test@example.com",
        name: "Lauren",
        height: 64,
        weight: 116,
        mantra: "you are limitless",
        primaryActivity: "Running",
        gender: "Female",
        biologicalSex: "Female",
        birthday: Calendar.current.date(from: DateComponents(year: 1997, month: 1, day: 31))!
    )

    ProfileView(profile: mockProfile)
        .modelContainer(for: UserProfile.self, inMemory: true)
}
