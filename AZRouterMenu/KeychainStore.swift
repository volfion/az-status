import Foundation
import Security

enum KeychainStore {
    static let service = "azrouter-swiftbar"
    static let account = "azrouter"

    static func readPassword() throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess,
              let data = item as? Data,
              let password = String(data: data, encoding: .utf8) else {
            if status == errSecItemNotFound {
                throw KeychainError.passwordNotFound
            }
            throw KeychainError.unexpectedStatus(status)
        }
        return password
    }

    static func savePassword(_ password: String) throws {
        let data = Data(password.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let update: [String: Any] = [kSecValueData as String: data]
        let updateStatus = SecItemUpdate(query as CFDictionary, update as CFDictionary)

        if updateStatus == errSecItemNotFound {
            var add = query
            add[kSecValueData as String] = data
            let addStatus = SecItemAdd(add as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainError.unexpectedStatus(addStatus)
            }
        } else if updateStatus != errSecSuccess {
            throw KeychainError.unexpectedStatus(updateStatus)
        }
    }
}

enum KeychainError: LocalizedError {
    case passwordNotFound
    case unexpectedStatus(OSStatus)

    var errorDescription: String? {
        switch self {
        case .passwordNotFound:
            return "Heslo nebylo nalezeno v Klíčence macOS."
        case .unexpectedStatus(let status):
            return "Klíčenka vrátila chybu \(status)."
        }
    }
}
