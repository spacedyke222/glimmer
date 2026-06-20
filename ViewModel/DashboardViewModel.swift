//
//  DashboardViewModel.swift
//  TRunD
//
//  Created by Lauren Harrell on 11/24/25.
//

import Foundation
import Combine
import AVFoundation

class DashboardViewModel: ObservableObject {
    @Published var latestReading: BGReading?
    @Published var dashboardError: String?

    @Published var announcementsEnabled: Bool {
        didSet { UserDefaults.standard.set(announcementsEnabled, forKey: Keys.enabled) }
    }
    @Published var readingInterval: Int {   // minutes between spoken announcements
        didSet {
            UserDefaults.standard.set(readingInterval, forKey: Keys.interval)
            startReadingTimer()
        }
    }

    private var feedTimer: AnyCancellable?
    private var readingTimer: AnyCancellable?
    private let speechSynthesizer = AVSpeechSynthesizer()

    private enum Keys {
        static let enabled = "voiceAnnouncementsEnabled"
        static let interval = "readingIntervalMinutes"
    }

    init() {
        let defaults = UserDefaults.standard
        announcementsEnabled = defaults.bool(forKey: Keys.enabled)
        readingInterval = (defaults.object(forKey: Keys.interval) as? Int) ?? 5
        startLibreFeed()
        startReadingTimer()
    }
    
    private func startLibreFeed() {
        // LibreLinkUp refreshes about once a minute.
        feedTimer = Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshReading()
            }
        refreshReading() // fetch immediately so the dashboard isn't blank at launch
    }

    private func refreshReading() {
        Task { [weak self] in
            do {
                let reading = try await LibreService.shared.fetchLatestReading()
                let bgReading = reading.toBGReading()
                await MainActor.run {
                    self?.latestReading = bgReading
                    self?.dashboardError = nil
                }
            } catch {
                print("Libre dashboard fetch error:", error)
                let description = (error as? LibreError)?.errorDescription ?? "\(error)"
                await MainActor.run {
                    self?.dashboardError = description
                }
            }
        }
    }

    func startReadingTimer() {
        readingTimer?.cancel()
        readingTimer = Timer.publish(every: TimeInterval(readingInterval * 60), on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, self.announcementsEnabled,
                      let value = self.latestReading?.value else { return }
                self.speakBGValue(Int(value))
            }
    }
    
    /// Speaks an announcement immediately — used by the Settings "Test Voice"
    /// button so audio can be verified on the spot, without waiting for the
    /// timer or a fresh Libre reading.
    func testVoice() {
        let value = latestReading.map { Int($0.value) } ?? 120
        speakBGValue(value)
    }

    private func speakBGValue(_ value: Int) {
        // A glucose announcement must be audible even on silent (or with the
        // Action Button toggled to silent) — that's the whole point. Configure
        // and activate the session OFF the main thread: AVAudioSession.setActive
        // is synchronous and blocks the main thread (doing it on-main is what
        // froze the app), and AVAudioSession is thread-safe. Then speak back on
        // the main actor.
        Task.detached(priority: .userInitiated) { [weak self] in
            let session = AVAudioSession.sharedInstance()
            try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try? session.setActive(true)
            await MainActor.run {
                guard let self else { return }
                let utterance = AVSpeechUtterance(string: "Your blood glucose is \(value)")
                utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                self.speechSynthesizer.speak(utterance)
            }
        }
    }
}
