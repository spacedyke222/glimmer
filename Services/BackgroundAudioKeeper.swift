//
//  BackgroundAudioKeeper.swift
//  TRunD (Glimmer)
//
//  Owns the audio *session* that spoken glucose announcements play through, so
//  they stay audible during a workout (silent switch on, mixed with music,
//  screen locked).
//
//  It does NOT keep the app alive by playing a tone. An earlier version drove a
//  continuous silent 440 Hz sine wave through an AVAudioEngine for that — which
//  caused IPCAUClient (-66748) failures and starved the main thread. Keeping the
//  app alive is `RunLocationKeeper`'s job (the location stream). Do not re-add
//  the audio engine here.
//
//  Activation runs OFF the main thread: `AVAudioSession.setActive` is
//  synchronous and can block while it negotiates with the media server, which
//  froze the UI the instant a run started. AVAudioSession is thread-safe, so we
//  do it on a background task and never stall the Start tap.
//

import AVFoundation
import CoreLocation

@MainActor
final class BackgroundAudioKeeper {
    static let shared = BackgroundAudioKeeper()

    private var isActive = false
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

    /// Call when a workout starts — activates the playback session (off-main) so
    /// announcements are audible even with the silent switch on or music playing.
    func start() {
        wantsKeepAlive = true
        guard !isActive else { return }
        isActive = true
        Task.detached(priority: .userInitiated) {
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playback, mode: .spokenAudio, options: [.mixWithOthers])
                try session.setActive(true)
            } catch {
                print("BackgroundAudioKeeper: audio session error:", error)
                await Self.shared.markInactive()
            }
        }
    }

    /// Call when a workout ends.
    func stop() {
        wantsKeepAlive = false
        guard isActive else { return }
        isActive = false
        Task.detached(priority: .utility) {
            try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        }
    }

    private func markInactive() { isActive = false }

    private func handleInterruption(_ note: Notification) {
        guard let info = note.userInfo,
              let raw = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: raw) else { return }
        switch type {
        case .began:
            isActive = false
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
