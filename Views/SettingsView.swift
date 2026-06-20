

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var viewModel: DashboardViewModel
    @State private var watchNotificationsEnabled = false
    @State private var selectedInterval = 15

    @Environment(\.openURL) private var openURL
    @StateObject private var libreAuth = LibreAuthState.shared
    @State private var showLibreLogin = false

    // Interval options
    let intervals = [1, 2, 3, 5, 10, 15, 20, 30, 45, 60]


    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ShimmerBackground()

                ScrollView {
                VStack(spacing: 24) {

                    // Custom title aligned to the right
                            HStack {
                                Text("Settings")
                                    .font(.largeTitle).bold()
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.top)


                    // --- Voice Announcements Card ---
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        .frame(height: 120)
                        .overlay(
                            VStack(alignment: .leading, spacing: 16) {
                                HStack(spacing: 12) {
                                    Image(systemName: "person.wave.2")
                                        .foregroundColor(.white)
                                        .font(.title2)
                                    Toggle(isOn: $viewModel.announcementsEnabled) {
                                        Text("Voice Announcements")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                    }
                                }
                                .toggleStyle(SwitchToggleStyle(tint: Color.orange))

                                // Interval picker shows only if enabled
                                if viewModel.announcementsEnabled {
                                    Picker("Interval", selection: $viewModel.readingInterval) {
                                        ForEach(intervals, id: \.self) { interval in
                                            Text("\(interval) min").tag(interval)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                }
                            }
                            .padding()
                        )

                    // Test voice button — instant check, independent of the 5-min timer
                    if viewModel.announcementsEnabled {
                        Button {
                            viewModel.testVoice()
                        } label: {
                            Label("Test Voice", systemImage: "speaker.wave.2.fill")
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(.ultraThinMaterial, in: Capsule())
                                .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
                        }
                    }

                    // --- Watch Notifications Card ---
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        .frame(height: 120)
                        .overlay(
                            VStack(alignment: .leading, spacing: 16) {

                                HStack(spacing: 12) {
                                    Image(systemName: "bell.fill")
                                        .foregroundColor(.white)
                                        .font(.title2)

                                Toggle(isOn: $watchNotificationsEnabled) {
                                    Text("Watch Notifications")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                                }
                                .toggleStyle(SwitchToggleStyle(tint: Color.pink))

                                if watchNotificationsEnabled {
                                    Picker("Interval", selection: $selectedInterval) {
                                        ForEach(intervals, id: \.self) { interval in
                                            Text("\(interval) min").tag(interval)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                }
                            }
                            .padding()
                        )

                    // Connect Watch Card
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .fill(.ultraThinMaterial)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                            )
                                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                                            .frame(height: 100)
                                            .overlay(
                                                Button(action: {
                                                    // TODO: Connect to Coros Watch via SDK/BLE
                                                    print("Connect Watch")
                                                }) {
                                                    HStack(spacing: 16) {
                                                        Image(systemName: "applewatch")
                                                            .foregroundColor(.white)
                                                            .font(.title2)
                                                        Text("Connect Watch")
                                                            .foregroundColor(.white)
                                                            .font(.headline)

                                                    }
                                                    .padding()
                                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                                }
                                            )



                    // --- Connect Libre Sensor (LibreLinkUp) ---
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        .frame(height: 100)
                        .overlay(
                            Button(action: {
                                showLibreLogin = true
                            }) {
                                HStack(spacing: 16) {
                                    Image(systemName: "dot.radiowaves.left.and.right")
                                        .foregroundColor(.white)
                                        .font(.title2)

                                    Text(libreAuth.isLoggedIn ? "Libre Sensor Connected" : "Connect Libre Sensor")
                                        .foregroundColor(.white)
                                        .font(.headline)

                                    if libreAuth.isLoggedIn {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding()
                            }
                        )

                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

            }
            .sheet(isPresented: $showLibreLogin) {
                LibreLoginView()
            }
            }

        }
    }
}

#Preview("Settings Page") {
    SettingsView()
        .environmentObject(DashboardViewModel())
}
