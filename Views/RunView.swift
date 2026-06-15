// RunView.swift
// Glimmer (previously TRunD)

import SwiftUI
import Charts
import Combine

// NOTE: This view is intended to be presented only within TabContainerView, which provides the universal toolbar.
// Do not wrap this in its own NavigationStack to ensure toolbar visibility.

// MARK: - Models

enum ActivityType: String, CaseIterable, Identifiable {
    case run, walk, bike, strength
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .run: return "Run"
        case .walk: return "Walk"
        case .bike: return "Bike"
        case .strength: return "Strength"
        }
    }

    var systemIconName: String {
        switch self {
        case .run: return "figure.run"
        case .walk: return "figure.walk"
        case .bike: return "bicycle"
        case .strength: return "dumbbell"
        }
    }
}

struct LiveReading: Identifiable {
    let id = UUID()
    let elapsedSeconds: Double
    let timestamp: Date
    let bg: Double
    
}

// MARK: - RunView

struct RunView: View {
    
    
    // Libre (CGM) auth
    @StateObject private var libreAuth = LibreAuthState.shared
    
    // Run state
    @State private var activity: ActivityType = .run
    @State private var isRunning = false
    @State private var runStartDate: Date? = nil
    @State private var elapsedSeconds: TimeInterval = 0
    
    // Data
    @State private var readings: [LiveReading] = []
    @State private var currentBG: Double = 100
    @State private var distanceMiles: Double = 0
    
    // Watch
    @State private var watchConnected = false
    @State private var connectingWatch = false
    
    // Timer
    @State private var libreTimer: Timer?

    /// Drives the elapsed-time display via a SwiftUI timer publisher instead of a
    /// hand-scheduled `Timer`. The old `startRunTimer()` created a `Timer` whose
    /// closure captured `self` (a View struct) and was double-registered on the
    /// run loop (`scheduledTimer` + `RunLoop.add(.common)`) — fragile, and the
    /// cause of the UI freezing a second into a run.
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // Environment
    @EnvironmentObject var workoutStore: WorkoutStore
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ShimmerBackground()

            VStack(spacing: 16) {
                
                // Top row: activity picker + watch connection
                HStack {
                    Menu {
                        ForEach(ActivityType.allCases) { type in
                            Button {
                                activity = type
                            } label: {
                                Label(type.displayName, systemImage: type.systemIconName)
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: activity.systemIconName)
                                .font(.title2)
                            Text(activity.displayName)
                                .font(.headline)
                        }
                        .padding(10)
                        .background(Color.indigo.opacity(0.6))
                        .shadow(color: .indigo, radius: 4, y:40)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    Spacer()
                    
                    if !watchConnected {
                        Button(action: connectWatchTapped) {
                            HStack(spacing: 10) {
                                Image(systemName: "applewatch")
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(connectingWatch ? "Connecting…" : "Connect Watch")
                                        .font(.subheadline).bold()
                                    Text(connectingWatch ? "Attempting connection" : "Tap to connect Coros")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(10)
                            
                            .cornerRadius(12)
                            .foregroundColor(.white)
                        }
                    } else {
                        HStack(spacing: 8) {
                            Circle().fill(Color.green).frame(width: 10, height: 10)
                            Text("Watch connected")
                                .font(.caption)
                        }
                        .padding(8)
                        .background(Color.black.opacity(0.25))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                    }
                }
                .padding(.horizontal)
                
                
                // Title
                HStack {
                    Text(isRunning ? "Recording — \(activity.displayName)" : "Ready to Record")
                        .font(.custom("Lato-Bold", size: 20))
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                    Spacer()
                }
                .padding(.horizontal)
                
                // Chart
                VStack(alignment: .leading, spacing: 8) {
                    Text("Glucose Reading")
                        .font(.custom("Lato-Regular", size: 20))
                        .foregroundColor(.white.opacity(0.9))

                    LiveBGChart(readings: readings, accent: .cyan)
                        .frame(height: 220)
                        .padding(.horizontal, -8)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                )
               
                .cornerRadius(16)
                .padding(.horizontal)
                
                // Stats
                HStack(spacing: 12) {
                    infoStat(title: "Elapsed", value: timeString(from: elapsedSeconds))
                    Divider().frame(height: 42).background(Color.gray)
                    infoStat(title: "BG", value: "\(Int(currentBG)) mg/dL")
                    Divider().frame(height: 42).background(Color.gray.opacity(0.25))
                    infoStat(title: "Distance", value: String(format: "%.2f mi", distanceMiles))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                        
                )
                
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Start/Stop
                VStack(spacing: 12) {
                    Button(action: { isRunning ? stopRun() : startRun() }) {
                        VStack {
                            Image(systemName: isRunning ? "stop.fill" : activity.systemIconName)
                                .font(.system(size: 34, weight: .bold))
                            Text(isRunning ? "End" : "Start")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isRunning ? Color.red : Color.indigo.opacity(0.6))
                        .shadow(color: .indigo, radius: 4, y:92)

                        .foregroundColor(.white)
                        .cornerRadius(18)
                        
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 20)
            }
            .padding(.top, -80)
        }
        .onReceive(ticker) { _ in
            guard isRunning, let start = runStartDate else { return }
            elapsedSeconds = Date().timeIntervalSince(start)
        }
        .onAppear {
            seedInitialReadingIfNeeded()
            attemptAutoReconnectWatch()
            
            if libreAuth.isLoggedIn { startLibreTimer() }
            attemptSilentLibreLogin()
        }
        .onDisappear {
            stopLibreTimer()
        }
        .onChange(of: libreAuth.isLoggedIn) { _, loggedIn in
            if loggedIn { startLibreTimer() } else { stopLibreTimer() }
        }
    }
    
    // MARK: - Helpers
    
    @ViewBuilder
    private func infoStat(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.custom("Lato-Bold", size: 12))
                .foregroundColor(.white.opacity(0.7))
            Text(value)
                .font(.custom("Lato-Light", size: 16))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func timeString(from seconds: TimeInterval) -> String {
        let s = Int(seconds)
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, sec) : String(format: "%02d:%02d", m, sec)
    }
    
    // MARK: - Run Control
    
    private func startRun() {
        guard watchConnected else { connectWatchTapped(); return }
        isRunning = true
        runStartDate = Date()
        elapsedSeconds = 0
        readings.removeAll()
        readings.append(LiveReading(elapsedSeconds: 0, timestamp: Date(), bg: Double(currentBG)))
        startLibreTimer()
        BackgroundAudioKeeper.shared.start()
        RunLocationKeeper.shared.start()
    }
    
    private func stopRun() {
        isRunning = false
        stopLibreTimer()
        BackgroundAudioKeeper.shared.stop()
        RunLocationKeeper.shared.stop()
        
        guard let start = runStartDate else { return }
        let workout = Workout(
            name: activity.displayName,
            date: start,
            duration: elapsedSeconds,
            distance: distanceMiles,
            readings: readings.map { $0.toBGReading() }
        )
        workoutStore.addWorkout(workout)
        
        runStartDate = nil
        elapsedSeconds = 0
        distanceMiles = 0
        readings.removeAll()
        seedInitialReadingIfNeeded()
    }
    
    private func seedInitialReadingIfNeeded() {
        guard readings.isEmpty else { return }
        readings = [LiveReading(elapsedSeconds: 0, timestamp: Date(), bg: Double(currentBG))]
    }
    
    // MARK: - Libre

    private func attemptSilentLibreLogin() {
        guard !libreAuth.isLoggedIn else { return }
        Task {
            // Silently reuse Keychain credentials; no UI if none are saved.
            try? await LibreService.shared.logInWithSavedCredentials()
        }
    }

    // MARK: - Timers
    
    private func startLibreTimer() {
        stopLibreTimer()
        // LibreLinkUp data refreshes about once a minute; polling faster just
        // repeats values and risks Abbott rate-limiting the unofficial API.
        libreTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            Task { await fetchLibreReading() }
        }
        RunLoop.main.add(libreTimer!, forMode: .common)
        Task { await fetchLibreReading() }
    }

    private func stopLibreTimer() {
        libreTimer?.invalidate()
        libreTimer = nil
    }
    
    @MainActor
    private func fetchLibreReading() async {
        do {
            let latest = try await LibreService.shared.fetchLatestReading()
            currentBG = latest.value
            if isRunning, let start = runStartDate {
                let elapsed = Date().timeIntervalSince(start)
                readings.append(LiveReading(elapsedSeconds: elapsed, timestamp: Date(), bg: currentBG))
            } else {
                readings = [LiveReading(elapsedSeconds: 0, timestamp: Date(), bg: currentBG)]
            }
        } catch {
            print("Libre fetch error:", error)
        }
    }
    
    // MARK: - Watch
    
    private func connectWatchTapped() {
        guard !watchConnected && !connectingWatch else { return }
        connectingWatch = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            watchConnected = true
            connectingWatch = false
        }
    }
    
    private func attemptAutoReconnectWatch() {
        guard !watchConnected else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            connectWatchTapped()
        }
    }
}

// MARK: - Live Chart

struct LiveBGChart: View {
    var readings: [LiveReading]
    var accent: Color
    
    var maxElapsed: Double {
        readings.map { $0.elapsedSeconds }.max() ?? 60
    }
    
    var body: some View {
        Chart {
            ForEach(readings) { r in
                LineMark(
                    x: .value("Elapsed", r.elapsedSeconds),
                    y: .value("BG", r.bg)
                )
                .foregroundStyle(LinearGradient(colors: [accent.opacity(0.9), accent.opacity(0.4)], startPoint: .top, endPoint: .bottom))
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                .interpolationMethod(.catmullRom)
                
                PointMark(x: .value("Elapsed", r.elapsedSeconds), y: .value("BG", r.bg))
                    .symbolSize(50)
                    .foregroundStyle(Color.white)
            }
        }
        .chartXScale(domain: 0...max(maxElapsed, 60))
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { value in
                AxisGridLine()
                    .foregroundStyle(Color.gray.opacity(0.25))

                AxisValueLabel {
                    if let secs = value.as(Double.self) {
                        Text("\(Int(secs / 60))m")
                    }
                }
                .font(.caption2)
                .foregroundStyle(Color.white.opacity(0.8))
            }
        }
        
        .chartYAxis { AxisMarks(position: .leading) { mark in
            AxisGridLine().foregroundStyle(Color.gray.opacity(0.25))
            AxisValueLabel().font(.caption2).foregroundStyle(Color.white.opacity(0.8))
        } }
        .chartYScale(domain: 40...250)
        .padding(.vertical, 6)
    }
}

// MARK: - Preview

#Preview {
    RunView()
        .environmentObject(WorkoutStore())
}

