//
//  KeychainManager.swift
//  TRunD
//

import Foundation
import Security
import CommonCrypto

nonisolated struct KeychainManager {
    
    static func savePassword(_ password: String, for email: String) -> Bool {
        guard let passwordData = password.data(using: .utf8) else { return false }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: email,
            kSecValueData as String: passwordData
        ]

        // delete old one if it exists
        SecItemDelete(query as CFDictionary)

        // save the new password
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    static func getPassword(for email: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: email,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess,
              let foundData = item as? Data,
              let password = String(data: foundData, encoding: .utf8)
        else { return nil }

        return password
    }
}

/// One-way password hashing for Glimmer's own local login (sign-up / log-in).
///
/// Deliberately NOT used for the LibreLinkUp password: that one must stay
/// recoverable in the Keychain because it's replayed to Abbott on every login.
/// This is only for the app's local account check, where we never need the
/// original value back — just to confirm a match.
nonisolated enum PasswordHasher {
    private static let iterations: UInt32 = 120_000
    private static let keyByteCount = 32
    private static let saltByteCount = 16

    /// Returns a self-describing `pbkdf2$<iterations>$<saltHex>$<hashHex>` string to store in the Keychain.
    static func makeStorageString(for password: String) -> String? {
        var salt = [UInt8](repeating: 0, count: saltByteCount)
        guard SecRandomCopyBytes(kSecRandomDefault, saltByteCount, &salt) == errSecSuccess,
              let hash = derive(password: password, salt: salt, iterationCount: iterations)
        else { return nil }
        return "pbkdf2$\(iterations)$\(hex(salt))$\(hex(hash))"
    }

    /// Constant-time verification of a password against a stored string from `makeStorageString`.
    static func verify(_ password: String, storage: String) -> Bool {
        let parts = storage.split(separator: "$")
        guard parts.count == 4, parts[0] == "pbkdf2",
              let iterationCount = UInt32(parts[1]),
              let salt = bytes(fromHex: String(parts[2])),
              let expected = bytes(fromHex: String(parts[3])),
              let actual = derive(password: password, salt: salt, iterationCount: iterationCount)
        else { return false }
        return constantTimeEqual(actual, expected)
    }

    private static func derive(password: String, salt: [UInt8], iterationCount: UInt32) -> [UInt8]? {
        let passwordBytes = Array(password.utf8).map { Int8(bitPattern: $0) }
        var derived = [UInt8](repeating: 0, count: keyByteCount)
        let status = CCKeyDerivationPBKDF(
            CCPBKDFAlgorithm(kCCPBKDF2),
            passwordBytes, passwordBytes.count,
            salt, salt.count,
            CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
            iterationCount,
            &derived, derived.count
        )
        return Int(status) == kCCSuccess ? derived : nil
    }

    private static func hex(_ bytes: [UInt8]) -> String {
        bytes.map { String(format: "%02x", $0) }.joined()
    }

    private static func bytes(fromHex string: String) -> [UInt8]? {
        guard string.count % 2 == 0 else { return nil }
        var result = [UInt8]()
        result.reserveCapacity(string.count / 2)
        var i = string.startIndex
        while i < string.endIndex {
            let j = string.index(i, offsetBy: 2)
            guard let byte = UInt8(string[i..<j], radix: 16) else { return nil }
            result.append(byte)
            i = j
        }
        return result
    }

    private static func constantTimeEqual(_ a: [UInt8], _ b: [UInt8]) -> Bool {
        guard a.count == b.count else { return false }
        var diff: UInt8 = 0
        for index in 0..<a.count { diff |= a[index] ^ b[index] }
        return diff == 0
    }
}
