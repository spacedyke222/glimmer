//
//  KeychainManager.swift
//  TRunD
//

import Foundation
import Security

struct KeychainManager {
    
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
