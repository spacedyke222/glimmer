import SwiftUI
import SwiftData

@main
struct TRunDApp: App {

    // MARK: - Stores
    @StateObject private var workoutStore = WorkoutStore()

    // MARK: - SwiftData container
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserProfile.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    // MARK: - App Entry Point
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(workoutStore)     // 👈 inject store
        }
        .modelContainer(sharedModelContainer)
    }
}
