import Foundation
import Security

/// Keychain-backed storage for provider API keys (ElevenLabs).
/// Nonisolated so `URLSessionBackendClient` can attach the key as
/// a request header from any context — it forwards to the backend
/// as `xi-api-key`, which the backend uses for ElevenLabs calls.
enum APIKeyStore {
    private static let service = "ai.coauthor.providers"
    private static let elevenLabsAccount = "elevenlabs-api-key"

    static var elevenLabsKey: String? {
        get { read(account: elevenLabsAccount) }
        set {
            if let value = newValue, !value.isEmpty {
                write(value, account: elevenLabsAccount)
            } else {
                delete(account: elevenLabsAccount)
            }
        }
    }

    /// Last four characters for masked display.
    static var elevenLabsKeyTail: String? {
        elevenLabsKey.map { String($0.suffix(4)) }
    }

    private static func read(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data
        else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func write(_ value: String, account: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        if SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess {
            SecItemUpdate(
                query as CFDictionary,
                [kSecValueData as String: data] as CFDictionary
            )
        } else {
            var attributes = query
            attributes[kSecValueData as String] = data
            SecItemAdd(attributes as CFDictionary, nil)
        }
    }

    private static func delete(account: String) {
        SecItemDelete([
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ] as CFDictionary)
    }
}
