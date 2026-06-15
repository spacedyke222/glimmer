# Glimmer

**Glimmer is a SwiftUI iOS app that speaks your blood glucose to you while you run.**
It's built for diabetic endurance athletes who can't safely glance at a phone mid-workout — Glimmer reads live Libre 3+ sensor data from the cloud and announces each value (with trend and a safe-to-run call) out loud, even with the screen locked.

> **Note on naming:** the Xcode project and folders use the internal codename **`TRunD`**; the shipping product is **Glimmer**. They refer to the same app.

<!-- TODO: add a screenshot or short screen-recording GIF here — it's the fastest way to show the dashboard, trend ring, and spoken-announcement flow. -->
<!-- ![Glimmer dashboard](docs/dashboard.png) -->

---

## Highlights

- **Live CGM integration over an `actor`-isolated service.** [`LibreService`](Services/LibreService.swift) talks to Abbott's LibreLinkUp "follower" cloud using Swift structured concurrency — `actor` isolation for all session state, `async/await` throughout, automatic token refresh, regional-host redirect handling (with a loop guard), and transparent re-login + retry on a mid-session `401`.
- **Spoken announcements that survive a locked screen.** [`BackgroundAudioKeeper`](Services/BackgroundAudioKeeper.swift) manages an `AVAudioSession` and `CLLocationManager` so `AVSpeechSynthesizer` announcements ([`DashboardViewModel`](ViewModel/DashboardViewModel.swift)) keep playing during a workout with the phone in a pocket — an accessibility-first design choice.
- **Secrets stay out of the binary and out of source.** Credentials are stored in the **Keychain** ([`KeychainManager`](Logging%20In/KeychainManager.swift)); the LibreLinkUp auth token lives only in memory on the `actor`. There are no hardcoded API keys — Glimmer authenticates with the user's own LibreLinkUp email/password.
- **Hand-drawn SwiftUI.** Custom `Shape`/`Path` work — [`JaggedCircle`](Asset/JaggedCircle.swift), [`Starburst`](Asset/Starburst.swift), and an animated trend arrow — plus a shimmer effect and custom fonts.
- **Real MVVM.** Clean separation across `Models / Views / ViewModel / Services / Toolbar / Asset`, `SwiftData` persistence for the user profile, and unit + UI test targets.

---

## How the Libre integration works

The Libre 3+ phone app uploads readings to Abbott's **LibreView** cloud, which exposes them to a designated **LibreLinkUp** follower. Glimmer signs in as that follower:

1. `POST /llu/auth/login` with the user's LibreLinkUp email/password → auth ticket (Bearer token) + the account's regional host.
2. Subsequent calls are pinned to that regional host and carry the Bearer token plus a `SHA256(userId)` `Account-Id` header (required by LibreLinkUp).
3. `GET /llu/connections` resolves the sensor; `GET /llu/connections/{id}/graph` returns the recent curve. The dashboard polls about once a minute (matching the sensor's cadence).

> ⚠️ **LibreLinkUp has no official public API.** The endpoints, headers, and `appVersion` value are community-reverse-engineered and can change without notice. `LibreService` documents this inline and is written so a single `appVersion` bump is usually enough to recover if Abbott changes the contract.

**Running it yourself:** live data requires LibreLinkUp credentials linked to a real Libre 3+ sensor, so the dashboard is best demonstrated via the screenshot/GIF above rather than a fresh simulator build.

---

## Tech stack

`Swift` · `SwiftUI` · `Swift Concurrency (actor / async-await / @MainActor)` · `Combine` · `SwiftData` · `AVFoundation (TTS + audio session)` · `CoreLocation` · `CryptoKit` · `Security (Keychain)` · `URLSession` · `XCTest`

## Project structure

```
Models/        BGReading and core data types
Views/         Dashboard, stats, history, profile, settings, trophies
ViewModel/     DashboardViewModel (polling + TTS), UserProfile, WorkoutStore
Services/      LibreService (CGM), BackgroundAudioKeeper, WorkoutAdvisor
Logging In/    Login / sign-up / Libre connect screens + KeychainManager
Asset/         Custom SwiftUI shapes & cards (JaggedCircle, Starburst, TrendArrow)
Toolbar/       Custom tab bar
```

## Requirements

- Xcode 16+, iOS 17+ (uses `SwiftData` and current Swift concurrency)
- Open `TRunD.xcodeproj` and run the **TRunD** scheme.
