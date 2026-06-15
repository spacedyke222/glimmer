//
//  BackgroundAudioKeeper.swift
//  TRunD (Glimmer)
//
//  Keeps the app running while a workout is in progress so glucose
//  announcements still fire with the screen locked / phone pocketed.
//
//  iOS suspends a backgrounded app once it stops producing audio. Declaring
//  the `audio` background mode (Info.plist) plus playing a continuous
//  vanishingly-quiet tone keeps the process alive. Paired with
//  `RunLocationKeeper`, which receives a location stream — the location
//  stream is the most reliable suspension blocker on modern iOS.
//

import AVFoundation
import CoreLocation

@MainActor
final class BackgroundAudioKeeper {
    static let shared = BackgroundAudioKeeper()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!

    private var isWired = false
    private var isRunning = false
    private var wantsKeepAlive = false

    private init() {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            MainActor.assumeIsolated { self?.handleInterruption(note) }
        }
    }

    /// Call when a workout starts.
    func start() {
        wantsKeepAlive = true
        guard !isRunning else { return }

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .spokenAudio, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("BackgroundAudioKeeper: audio session error:", error)
            return
        }

        if !isWired {
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            isWired = true
        }

        do {
            try engine.start()
        } catch {
            print("BackgroundAudioKeeper: engine start error:", error)
            return
        }

        player.scheduleBuffer(silentBuffer(), at: nil, options: .loops, completionHandler: nil)
        player.play()
        isRunning = true
    }

    /// Call when a workout ends.
    func stop() {
        wantsKeepAlive = false
        guard isRunning else { return }
        player.stop()
        engine.stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        isRunning = false
    }

    private func silentBuffer() -> AVAudioPCMBuffer {
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 4_410)!
        buffer.frameLength = buffer.frameCapacity
        let amplitude: Float = 1e-4
        let sampleRate = Float(format.sampleRate)
        let frequency: Float = 440
        if let channels = buffer.floatChannelData {
            for channel in 0..<Int(format.channelCount) {
                let ptr = channels[channel]
                for frame in 0..<Int(buffer.frameLength) {
                    let t = Float(frame) / sampleRate
                    ptr[frame] = amplitude * sin(2 * Float.pi * frequency * t)
                }
            }
        }
        return buffer
    }

    private func handleInterruption(_ note: Notification) {
        guard let info = note.userInfo,
              let raw = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: raw) else { return }
        switch type {
        case .began:
            isRunning = false
        case .ended:
            if wantsKeepAlive { start() }
        @unknown default:
            break
        }
    }
}

// MARK: - Run location keep-alive

@MainActor
final class RunLocationKeeper: NSObject {
    static let shared = RunLocationKeeper()

    private let locationManager = CLLocationManager()
    private var isRunning = false
    private var wantsKeepAlive = false

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = 50
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
    }

    func start() {
        wantsKeepAlive = true
        startIfAuthorized()
    }

    func stop() {
        wantsKeepAlive = false
        guard isRunning else { return }
        locationManager.stopUpdatingLocation()
        isRunning = false
    }

    private func startIfAuthorized() {
        guard !isRunning else { return }
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            print("RunLocationKeeper: location permission denied — background keep-alive won't work.")
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
            isRunning = true
        @unknown default:
            break
        }
    }
}

extension RunLocationKeeper: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // No-op — receiving updates is what keeps the app alive.
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        print("RunLocationKeeper error:", error)
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        MainActor.assumeIsolated {
            if self.wantsKeepAlive && !self.isRunning {
                self.startIfAuthorized()
            }
        }
    }
}
