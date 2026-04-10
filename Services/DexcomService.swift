import Foundation
import Combine

actor DexcomService {
    static let shared = DexcomService()
    
    // MARK: - Configuration
    private let clientID = "Ck94kCzV5OrFTohbLYoUGLv6N0IaBf8s"
    private let clientSecret = "ADc7jkyaWLUg2SNe"
    private let redirectURI = "glimmer://auth" // Must match DexcomAuthManager
    
    private let tokenURL = "https://sandbox-api.dexcom.com/v2/oauth2/token"
    private let egvsURL = "https://sandbox-api.dexcom.com/v3/users/self/egvs"
    
    private var accessToken: String?
    private var refreshToken: String?
    
    // MARK: - Token Management
    func setToken(access: String, refresh: String) {
        accessToken = access
        refreshToken = refresh
        Task { @MainActor in
            DexcomAuthState.shared.isLoggedIn = true
        }
    }
    
    func clearToken() {
        accessToken = nil
        refreshToken = nil
        Task { @MainActor in
            DexcomAuthState.shared.isLoggedIn = false
        }
    }

    // MARK: - OAuth Logic
    func exchangeCodeForToken(_ code: String) async throws {
        guard let url = URL(string: tokenURL) else { throw DexcomError.invalidURL }
        
        // Use URLComponents for safe x-www-form-urlencoded encoding
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "client_secret", value: clientSecret),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "redirect_uri", value: redirectURI)
        ]
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.httpBody = components.query?.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: req)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw DexcomError.authFailed
        }
        
        let token = try JSONDecoder().decode(TokenResponse.self, from: data)
        setToken(access: token.access_token, refresh: token.refresh_token)
    }
    
    private func refreshAccessToken() async throws {
        guard let refresh = refreshToken, let url = URL(string: tokenURL) else { throw DexcomError.notAuthenticated }
        
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "client_secret", value: clientSecret),
            URLQueryItem(name: "refresh_token", value: refresh),
            URLQueryItem(name: "grant_type", value: "refresh_token")
        ]
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.httpBody = components.query?.data(using: .utf8)
        
        let (data, _) = try await URLSession.shared.data(for: req)
        let token = try JSONDecoder().decode(TokenResponse.self, from: data)
        accessToken = token.access_token
        refreshToken = token.refresh_token
    }
    
    // MARK: - Fetch Data
    func fetchEGVS() async throws -> [DexcomEGV] {
        guard let token = accessToken else { throw DexcomError.notAuthenticated }
        
        let formatter = ISO8601DateFormatter()
        let now = formatter.string(from: Date())
        let window = formatter.string(from: Date().addingTimeInterval(-1800)) // 30 min window
        
        var components = URLComponents(string: egvsURL)!
        components.queryItems = [
            URLQueryItem(name: "startDate", value: window),
            URLQueryItem(name: "endDate", value: now)
        ]
        
        var req = URLRequest(url: components.url!)
        req.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: req)
        
        if let http = response as? HTTPURLResponse, http.statusCode == 401 {
            try await refreshAccessToken()
            return try await fetchEGVS() // Recursive retry once
        }
        
        let decoded = try JSONDecoder().decode(EGVSResponse.self, from: data)
        return decoded.records
    }
}

// MARK: - Updated V3 Models
@MainActor
class DexcomAuthState: ObservableObject {
    static let shared = DexcomAuthState()
    
    @Published var isLoggedIn: Bool = false
    
    private init() {} // Prevents multiple instances
}

struct TokenResponse: Codable {
    let access_token: String
    let refresh_token: String
    let expires_in: Int?
    let token_type: String?
}


struct EGVSResponse: Codable {
    let records: [DexcomEGV]
}

struct DexcomEGV: Codable {
    let value: Double?
    let realtimeValue: Double?
    let smoothedValue: Double?
    let status: String?
    let trend: String?
    let systemTime: String
    
    // Helper to get the best available number
    var displayValue: Int {
        Int(value ?? realtimeValue ?? smoothedValue ?? 0)
    }
}

enum DexcomError: Error {
    case notAuthenticated
    case invalidURL
    case authFailed
}
