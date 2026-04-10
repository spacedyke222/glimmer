//
//  DashboardViewModel.swift
//  TRunD
//
//  Created by Bitch Bag 1 on 11/24/25.
//

import Foundation
import Combine
import AVFoundation

class DashboardViewModel: ObservableObject {
    @Published var latestReading: BGReading?
    @Published var readingInterval: Int = 5 // minutes

    private var timer: AnyCancellable?
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var readingTimer: AnyCancellable?

    init() {
        startMockDataFeed()
        startReadingTimer()
    }
    
    private func startMockDataFeed() {
        timer = Timer.publish(every: 5, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                self.latestReading = BGReading(
                    value: Double(Int.random(in: 90...180)),
                    trend: "steady",
                    timestamp: Date(),
                    pace: Double.random(in: 4.0...20.0) // pace in minutes per mile
                )
            }
    }

    func startReadingTimer() {
        // Cancel any existing timer
        readingTimer?.cancel()
        // Start new timer at the selected interval
        readingTimer = Timer.publish(every: TimeInterval(readingInterval * 60), on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                if let value = self?.latestReading?.value {
                    self?.speakBGValue(Int(value))
                }
            }
    }
    
    func updateInterval(_ newInterval: Int) {
        readingInterval = newInterval
        startReadingTimer()
    }
    
    private func speakBGValue(_ value: Int) {
        let utterance = AVSpeechUtterance(string: "Your blood glucose is \(value)")
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        speechSynthesizer.speak(utterance)
    }
}
