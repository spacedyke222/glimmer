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
    
    private func speakBGValue(_ value: Int) {
        let utterance = AVSpeechUtterance(string: "Your blood glucose is \(value)")
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        speechSynthesizer.speak(utterance)
    }
}
