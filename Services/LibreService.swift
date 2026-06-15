//
//  LibreService.swift
//  TRunD (Glimmer)
//
//  Reads Libre 3 / 3+ glucose from Abbott's LibreLinkUp "follower" cloud.
//  The Libre phone app uploads readings to LibreView, and LibreLinkUp
//  exposes them to a designated follower.
//
//  LibreLinkUp has no official public API. The endpoints, headers, and the
//  `appVersion` value below are community-reverse-engineered and can change
//  without notice — if requests start failing, bump `appVersion` first.
//

import Foundation
import CryptoKit
import Combine

// MARK: - Auth state

@MainActor
final class LibreAuthState: ObservableObject {
    static let shared = LibreAuthState()
    @Published var isLoggedIn: Bool = false
    private init() {}
}

// MARK: - Service

actor LibreService {
    static let shared = LibreService()
    private init() {}

    // MARK: Configuration

    /// LibreLinkUp app version Abbott expects in the `version` header.
    /// Abbott rejects stale values — bump this if logins start failing.
    private let appVersion = "4.16.0"

    /// First-contact host. Abbott's login reply tells us the real regional
    /// host to use from then on (see `redirect` handling in `performLogin`).
    private let defaultHost = "https://api.libreview.io"

    private let regionKey = "glimmer.libre.region"
    private let emailDefaultsKey = "glimmer.libre.email"
    private let keychainAccount = "glimmer.libre.linkup"

    // MARK: Session state

    private var token: String?
    private var tokenExpiry: Date?
    private var accountIdHash: String?   // SHA256(userId), required on data requests
    private var patientId: String?

    private var baseURL: String {
        if let region = UserDefaults.standard.string(forKey: regionKey), !region.isEmpty {
            return "https://api-\(region).libreview.io"
        }
        return defaultHost
    }

    var isSignedIn: Bool { token != nil }

    // MARK: - Credentials

    /// LibreView email/password. Password lives in the Keychain under a
    /// namespaced account so it never collides with Glimmer's own logins.
    func saveCredentials(email: String, password: String) {
        UserDefaults.standard.set(email, forKey: emailDefaultsKey)
        _ = KeychainManager.savePassword(password, for: keychainAccount)
    }

    func clearCredentials() {
        UserDefaults.standard.removeObject(forKey: emailDefaultsKey)
        UserDefaults.standard.removeObject(forKey: regionKey)
        _ = KeychainManager.savePassword("", for: keychainAccount)
    }

    private func savedCredentials() -> (email: String, password: String)? {
        guard let email = UserDefaults.standard.string(forKey: emailDefaultsKey), !email.isEmpty,
              let password = KeychainManager.getPassword(for: keychainAccount), !password.isEmpty
        else { return nil }
        return (email, password)
    }

    // MARK: - Authentication

    func logIn(email: String, password: String) async throws {
        try await performLogin(email: email, password: password, followedRedirect: false)
        saveCredentials(email: email, password: password)
    }

    func logInWithSavedCredentials() async throws {
        guard let creds = savedCredentials() else { throw LibreError.missingCredentials }
        try await performLogin(email: creds.email, password: creds.password, followedRedirect: false)
    }

    func logOut() async {
        token = nil
        tokenExpiry = nil
        accountIdHash = nil
        patientId = nil
        clearCredentials()
        await setLoggedIn(false)
    }

    private func performLogin(email: String, password: String, followedRedirect: Bool) async throws {
        guard let url = URL(string: "\(baseURL)/llu/auth/login") else { throw LibreError.invalidURL }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        applyCommonHeaders(to: &req)
        req.httpBody = try JSONEncoder().encode(["email": email, "password": password])

        let (data, response) = try await URLSession.shared.data(for: req)
        try Self.validateHTTP(response, data: data)

        let decoded = try JSONDecoder().decode(LibreLoginResponse.self, from: data)

        // Abbott pins accounts to a regional host; the first login tells us which.
        if let payload = decoded.data, payload.redirect == true, let region = payload.region {
            guard !followedRedirect else { throw LibreError.regionRedirectLoop }
            UserDefaults.standard.set(region, forKey: regionKey)
            try await performLogin(email: email, password: password, followedRedirect: true)
            return
        }

        guard decoded.status == 0,
              let ticket = decoded.data?.authTicket,
              let userId = decoded.data?.user?.id
        else { throw LibreError.loginFailed(status: decoded.status) }

        token = ticket.token
        tokenExpiry = Date(timeIntervalSince1970: ticket.expires)
        accountIdHash = Self.sha256Hex(userId)
        patientId = nil

        await setLoggedIn(true)
    }

    private func ensureValidToken() async throws {
        if token != nil, let expiry = tokenExpiry, expiry > Date().addingTimeInterval(60) {
            return
        }
        try await logInWithSavedCredentials()
    }

    // MARK: - Fetch Data

    /// The single most recent glucose value — what the spoken announcements need.
    func fetchLatestReading() async throws -> LibreGlucoseReading {
        let connection = try await loadConnection()
        guard let measurement = connection.glucoseMeasurement else {
            throw LibreError.noConnection
        }
        return LibreGlucoseReading(from: measurement)
    }

    /// Recent history (roughly the last 12 hours) plus the current value,
    /// sorted oldest-first so `.last` is the freshest reading.
    func fetchReadings() async throws -> [LibreGlucoseReading] {
        let id: String
        if let cached = patientId {
            id = cached
        } else {
            id = try await loadConnection().patientId
        }

        try await ensureValidToken()
        let data = try await authedGET("/llu/connections/\(id)/graph")
        let decoded = try JSONDecoder().decode(LibreGraphResponse.self, from: data)
        guard decoded.status == 0, let payload = decoded.data else {
            throw LibreError.noConnection
        }

        var readings = (payload.graphData ?? []).map(LibreGlucoseReading.init(from:))
        if let current = payload.connection?.glucoseMeasurement {
            readings.append(LibreGlucoseReading(from: current))
        }
        return readings.sorted { $0.timestamp < $1.timestamp }
    }

    private func loadConnection() async throws -> LibreConnection {
        try await ensureValidToken()
        let data = try await authedGET("/llu/connections")
        let decoded = try JSONDecoder().decode(LibreConnectionsResponse.self, from: data)
        guard decoded.status == 0, let connection = decoded.data?.first else {
            throw LibreError.noConnection
        }
        patientId = connection.patientId
        return connection
    }

    // MARK: - Networking

    private func authedGET(_ path: String) async throws -> Data {
        guard let url = URL(string: baseURL + path) else { throw LibreError.invalidURL }

        var req = URLRequest(url: url)
        try applyAuthHeaders(to: &req)
        let (data, response) = try await URLSession.shared.data(for: req)

        // Token rejected mid-session — re-login once with saved credentials and retry.
        if let http = response as? HTTPURLResponse, http.statusCode == 401 {
            try await logInWithSavedCredentials()
            var retry = URLRequest(url: url)
            try applyAuthHeaders(to: &retry)
            let (retryData, retryResponse) = try await URLSession.shared.data(for: retry)
            try Self.validateHTTP(retryResponse, data: retryData)
            return retryData
        }

        try Self.validateHTTP(response, data: data)
        return data
    }

    private func applyCommonHeaders(to req: inout URLRequest) {
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("llu.ios", forHTTPHeaderField: "product")
        req.setValue(appVersion, forHTTPHeaderField: "version")
        req.setValue("Keep-Alive", forHTTPHeaderField: "Connection")
        req.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        req.setValue("LibreLinkUp/\(appVersion) (com.abbott.LibreLinkUp.iOS; iOS) Alamofire/5.9.1",
                     forHTTPHeaderField: "User-Agent")
    }

    private func applyAuthHeaders(to req: inout URLRequest) throws {
        guard let token else { throw LibreError.notAuthenticated }
        applyCommonHeaders(to: &req)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        // Required by LibreLinkUp since late 2023; data calls 401 without it.
        if let accountIdHash {
            req.setValue(accountIdHash, forHTTPHeaderField: "Account-Id")
        }
    }

    private func setLoggedIn(_ value: Bool) async {
        await MainActor.run { LibreAuthState.shared.isLoggedIn = value }
    }

    private static func validateHTTP(_ response: URLResponse, data: Data? = nil) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200...299).contains(http.statusCode) else {
            let body = data
                .flatMap { String(data: $0, encoding: .utf8) }
                .map { String($0.prefix(200)) }
                ?? ""
            #if DEBUG
            print("LibreService HTTP \(http.statusCode):", body)
            #endif
            throw LibreError.serverError(code: http.statusCode, body: body)
        }
    }

    private static func sha256Hex(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Public reading type

nonisolated enum LibreTrend: Int {
    case unknown     = 0
    case fallingFast = 1
    case falling     = 2
    case steady      = 3
    case rising      = 4
    case risingFast  = 5

    init(arrow: Int?) {
        self = LibreTrend(rawValue: arrow ?? 0) ?? .unknown
    }

    /// Trend string in the same freeform style BGReading already stores.
    var label: String {
        switch self {
        case .fallingFast: return "fallingFast"
        case .falling:     return "falling"
        case .rising:      return "rising"
        case .risingFast:  return "risingFast"
        case .steady, .unknown: return "steady"
        }
    }
}

nonisolated struct LibreGlucoseReading {
    let value: Double          // mg/dL
    let timestamp: Date
    let trend: LibreTrend

    init(from measurement: LibreGlucoseMeasurement) {
        value = measurement.valueInMgPerDl
        trend = LibreTrend(arrow: measurement.trendArrow)
        timestamp = LibreGlucoseReading.parseTimestamp(measurement.timestamp) ?? Date()
    }

    @MainActor func toBGReading(pace: Double? = nil) -> BGReading {
        BGReading(value: value, trend: trend.label, timestamp: timestamp, pace: pace)
    }

    /// LibreLinkUp returns timestamps as US-formatted strings ("M/d/yyyy h:mm:ss a") in UTC.
    private static func parseTimestamp(_ raw: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "M/d/yyyy h:mm:ss a"
        return formatter.date(from: raw)
    }
}

nonisolated enum LibreError: LocalizedError {
    case invalidURL
    case notAuthenticated
    case missingCredentials
    case loginFailed(status: Int)
    case regionRedirectLoop
    case noConnection
    case serverError(code: Int, body: String = "")

    var errorDescription: String? {
        switch self {
        case .invalidURL:         return "Could not build the LibreLinkUp request URL."
        case .notAuthenticated:   return "Not signed in to LibreLinkUp."
        case .missingCredentials: return "No saved LibreLinkUp credentials."
        case .loginFailed(let s): return "LibreLinkUp login failed (status \(s)). Check your email and password."
        case .regionRedirectLoop: return "LibreLinkUp kept redirecting between regions."
        case .noConnection:       return "No Libre sensor connection found. Make sure LibreLinkUp sharing is set up."
        case .serverError(let c, let body):
            return body.isEmpty
                ? "LibreLinkUp server error (HTTP \(c))."
                : "LibreLinkUp server error (HTTP \(c)) — \(body)"
        }
    }
}

// MARK: - LibreLinkUp wire models

private nonisolated struct LibreLoginResponse: Decodable {
    let status: Int
    let data: LoginData?

    nonisolated struct LoginData: Decodable {
        let authTicket: AuthTicket?
        let user: User?
        let redirect: Bool?
        let region: String?
    }
    nonisolated struct AuthTicket: Decodable {
        let token: String
        let expires: TimeInterval
    }
    nonisolated struct User: Decodable {
        let id: String
    }
}

private nonisolated struct LibreConnectionsResponse: Decodable {
    let status: Int
    let data: [LibreConnection]?
}

private nonisolated struct LibreGraphResponse: Decodable {
    let status: Int
    let data: GraphData?

    nonisolated struct GraphData: Decodable {
        let connection: LibreConnection?
        let graphData: [LibreGlucoseMeasurement]?
    }
}

nonisolated struct LibreConnection: Decodable {
    let patientId: String
    let glucoseMeasurement: LibreGlucoseMeasurement?
}

nonisolated struct LibreGlucoseMeasurement: Decodable {
    let timestamp: String
    let valueInMgPerDl: Double
    let trendArrow: Int?

    enum CodingKeys: String, CodingKey {
        case timestamp = "Timestamp"
        case valueInMgPerDl = "ValueInMgPerDl"
        case trendArrow = "TrendArrow"
    }
}
