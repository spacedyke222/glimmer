import SwiftUI
import SwiftData



struct MainView: View {
    @State private var selectedTab: Tab = .home
    @Query(sort: \UserProfile.name) var profiles: [UserProfile]

    var body: some View {
        if let profile = profiles.first {
            // user logged in → show dashboard and tabs
            TabContainerView(profile: profile)
        } else {
            // no saved profile → show login
            LoginView()
        }
    }
}

struct TabContainerView: View {
    @Bindable var profile: UserProfile
    @State private var selectedTab: Tab = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            // Screen switcher
            Group {
                switch selectedTab {
                case .home:
                    DashboardView(profile: profile)
                case .stats:
                    StatsView()
                case .profile:
                    ProfileView(profile: profile)
                case .activity:
                    RunView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()

            // Custom tab bar
            CustomToolbar(selectedTab: $selectedTab)
        }
    }
}
