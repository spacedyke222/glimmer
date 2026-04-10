

import SwiftUI

struct SettingsView: View {
    @State private var voiceAnnouncementsEnabled = false
    @State private var watchNotificationsEnabled = false
    @State private var selectedInterval = 15
    
    @Environment(\.openURL) private var openURL
    
    // Interval options
    let intervals = [5, 10, 15, 20, 30, 45, 60]

    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Custom title aligned to the right
                            HStack {
                                Text("Settings")
                                    .font(.largeTitle).bold()
                                    .foregroundColor(Color.indigo.opacity(0.6))
                                Spacer()
                            }
                            .padding(.top)
                        
                    
                    // --- Voice Announcements Card ---
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(gradient: Gradient(colors: [Color.purple, Color.pink]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color.indigo.opacity(0.2), radius: 8, x: 0, y: 4)
                        .frame(height: 120)
                        .overlay(
                            VStack(alignment: .leading, spacing: 16) {
                                HStack(spacing: 12) {
                                    Image(systemName: "person.wave.2")
                                        .foregroundColor(.white)
                                        .font(.title2)
                                    Toggle(isOn: $voiceAnnouncementsEnabled) {
                                        Text("Voice Announcements")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                    }
                                }
                                .toggleStyle(SwitchToggleStyle(tint: Color.orange))
                                
                                // Interval picker shows only if enabled
                                if voiceAnnouncementsEnabled {
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
                    
                    // --- Watch Notifications Card ---
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(gradient: Gradient(colors: [Color.purple, Color.orange]),
                                startPoint: .top,
                                endPoint: .bottom
                                )
                        )
                        .shadow(color: Color.indigo.opacity(0.2), radius: 8, x: 0, y: 4)
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
                                            .fill(
                                                LinearGradient(gradient: Gradient(colors: [Color.purple, Color.pink]),
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                            )
                                            .shadow(color: Color.indigo.opacity(0.2), radius: 8, x: 0, y: 4)
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
                    
    
                    
                    // --- Connect Sensor (Dexcom OAuth) ---
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple, Color.orange]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color.indigo.opacity(0.2), radius: 8, x: 0, y: 4)
                        .frame(height: 100)
                        .overlay(
                            Button(action: {
                                DexcomAuthManager.shared.startAuth()
                            }) {
                                HStack(spacing: 16) {
                                    Image(systemName: "dot.radiowaves.left.and.right")
                                        .foregroundColor(.white)
                                        .font(.title2)

                                    Text("Connect Sensor")
                                        .foregroundColor(.white)
                                        .font(.headline)
                                }
                                .padding()
                            }
                        )

                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

            }
            .background()
                    
        }
    }
}

#Preview("Settings Page") {
    SettingsView()
}


