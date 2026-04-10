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
                .onOpenURL { url in
                    handleDexcomRedirect(url)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}


// MARK: - Dexcom Redirect Handler
func handleDexcomRedirect(_ url: URL) {
    print("🔗 Received redirect URL: \(url.absoluteString)")

    // Extract authorization code
    if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
       let code = components.queryItems?.first(where: { $0.name == "code" })?.value {

        print("✅ Dexcom Authorization Code: \(code)")
        // TODO: Exchange this code for an access token + refresh token
    } else {
        print("❌ No auth code found in redirect URL.")
    }
}
