import SwiftUI
import SwiftData

struct DashboardView: View {
    @Bindable var profile: UserProfile
    @StateObject private var workoutStore = WorkoutStore()
    @StateObject private var viewModel = DashboardViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ShimmerBackground()
                
                VStack(spacing: 0) {
                    glucoseHeader
                    Spacer(minLength: 30)
                    cardsSection
                }
            }
        }
        .environmentObject(workoutStore)
    }
}

// MARK: - Sub-Views
private extension DashboardView {
    
    var backgroundGradient: some View {
        
        ShimmerBackground()
    }
    
    var glucoseHeader: some View {
        VStack(spacing: 30) {
            Text(profile.mantra)
                .font(.custom("Motterdam", size: 28))
                .foregroundColor(Color.white)
                .shadow(radius: 2)
                .padding(.top, 20)

            // Changed: Using viewModel directly
            if let reading = viewModel.latestReading {
                glucoseCircle(value: reading.value, trend: reading.trend)
            } else {
                ProgressView()
                    .tint(.white)
                    .frame(width: 240, height: 240)
            }
        }
    }
    
    func glucoseCircle(value: Double, trend: String) -> some View {
        VStack(spacing: 10) {
            // Check if convertTrend is actually in your ViewModel
            TrendArrowView(direction: convertTrend(trend))
            
            Text(value.formatted(.number.precision(.fractionLength(0))))
                .font(.system(size: 84, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.white)
                .shadow(radius: 4)
        }
        .frame(width: 240, height: 240)
        .background {
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color.purple, Color.cyan],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 8
                )
        }
    }
    
    var cardsSection: some View {
        ScrollView {
            VStack(spacing: 20) {
                statusCard
                historyLink
                badgesLink()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 100)
        }
        .frame(maxWidth: .infinity)
        .background {
            UnevenRoundedRectangle(topLeadingRadius: 30, topTrailingRadius: 30)
                .fill(Color.white.opacity(0.3))
                .ignoresSafeArea(edges: .bottom)
                .shadow(color: .black.opacity(0.15), radius: 12, y: -5)
        }
    }
}

// MARK: - Individual Cards
private extension DashboardView {
    var statusCard: some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Status")
                    .font(.custom("Lato-Regular", size: 20))
                    .foregroundColor(.white)

                Text("You're in a great zone for aerobic training.")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
        }
    }

    
    var historyLink: some View {
        NavigationLink(destination: WorkoutHistoryView()) {
            DashboardCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Workout History")
                        .font(.custom("Lato-Regular", size: 20))
                        .foregroundColor(.white)

                    Text("View past runs and BG trends")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }

    
    @ViewBuilder
    func badgesLink() -> some View {
        NavigationLink(destination: BadgesView()) {
            DashboardCard(minHeight: 110) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Badges")
                        .font(.custom("Lato-Regular", size: 20))
                        .foregroundColor(.white)

                    Text("Earn streaks and medals")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain) // Prevents the whole card from turning blue/faded on tap
    }
}


#Preview {
    // 1. Create a schema for your models
    let schema = Schema([UserProfile.self])
    
    // 2. Create an in-memory configuration (so it doesn't save to a real database)
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    
    do {
        // 3. Create the container
        let container = try ModelContainer(for: schema, configurations: config)
        
        // 4. Create dummy data
        let mockProfile = UserProfile(
            email: "test@example.com",
            name: "SwiftUI Developer",
            height: 70,
            weight: 160,
            mantra: "Glimmer",
            primaryActivity: "Running",
            gender: "Non-binary",
            biologicalSex: "Female",
            birthday: Date()
        )
        
        // 5. Add it to the container's context
        container.mainContext.insert(mockProfile)
        
        // 6. Return the view with the mock data
        return DashboardView(profile: mockProfile)
            .modelContainer(container)
            
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}
