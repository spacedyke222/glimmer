import Foundation
import AuthenticationServices
import UIKit
import Combine

@MainActor
final class DexcomAuthManager: NSObject, ObservableObject {
    
    static let shared = DexcomAuthManager()
    
    @Published var isLoggedIn: Bool = false
    
    private var session: ASWebAuthenticationSession?
    
    // MARK: - Configuration
    private let clientID = "Ck94kCzV5OrFTohbLYoUGLv6N0IaBf8s"
    private let clientSecret = "ADc7jkyaWLUg2SNe"
    
    // IMPORTANT: This must match exactly what is registered in the Dexcom Developer Portal
    private let redirectURI = "glimmer://auth"
    private let authBaseURL = "https://sandbox-api.dexcom.com/v2/oauth2/login"
    
    // MARK: - Start OAuth login
    func startAuth() {
        var components = URLComponents(string: authBaseURL)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "offline_access"),
            URLQueryItem(name: "state", value: UUID().uuidString) // Security best practice
        ]
        
        guard let url = components.url else { return }
        
        // callbackURLScheme is just "glimmer" (no ://)
        session = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: "glimmer"
        ) { [weak self] callbackURL, error in
            guard let self = self, let callbackURL = callbackURL else {
                if let error = error {
                    print("Auth session error: \(error.localizedDescription)")
                }
                return
            }
            
            self.handleCallback(url: callbackURL)
        }
        
        session?.presentationContextProvider = self
        session?.prefersEphemeralWebBrowserSession = false // Keep false if you want users to stay logged in
        session?.start()
    }
    
    private func handleCallback(url: URL) {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        guard let code = components?.queryItems?.first(where: { $0.name == "code" })?.value else {
            print("No authorization code found in callback")
            return
        }
        
        Task {
            do {
                try await DexcomService.shared.exchangeCodeForToken(code)
                self.isLoggedIn = true
            } catch {
                print("Dexcom token exchange failed:", error)
                self.isLoggedIn = false
            }
        }
    }
    
    func logout() {
        Task {
            await DexcomService.shared.clearToken()
            self.isLoggedIn = false
        }
    }
}

// MARK: - Presentation Context
extension DexcomAuthManager: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return ASPresentationAnchor()
        }
        return window
    }
}
