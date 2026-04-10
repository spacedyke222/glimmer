import SwiftUI
import SwiftData

struct DashboardWrapperView: View {
    @Query(sort: \UserProfile.name) var profiles: [UserProfile]  // fetch all user profiles

    var body: some View {
        // check if we have at least one profile
        if let profile = profiles.first {
            // pass the profile to the dashboard
            DashboardView(profile: profile)
        } else {
            // no profile found → send user to signup
            SignUpView()
        }
    }
}
