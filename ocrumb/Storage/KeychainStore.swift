import Foundation
import Security

/// Abstraction over token persistence so `SessionStore` can be tested
/// against an in-memory fake instead of the real system Keychain.
protocol TokenStore: AnyObject {
    var token: String? { get set }
}

final class KeychainStore: TokenStore {
    static let shared = KeychainStore()

    private let service = "com.plumcode.ocrumb"
    private let account = "authToken"

    var token: String? {
        get { read() }
        set {
            if let newValue { write(newValue) }
            else { delete() }
        }
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    private func read() -> String? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func write(_ value: String) {
        let data = Data(value.utf8)
        let update: [String: Any] = [kSecValueData as String: data]
        let status = SecItemUpdate(baseQuery() as CFDictionary, update as CFDictionary)
        if status == errSecItemNotFound {
            var insert = baseQuery()
            insert[kSecValueData as String] = data
            insert[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            SecItemAdd(insert as CFDictionary, nil)
        }
    }

    private func delete() {
        SecItemDelete(baseQuery() as CFDictionary)
    }
}
