import Foundation
import Security

/// Persists the JWT access & refresh tokens in the Keychain so they stay protected at rest
/// (the iOS counterpart of EncryptedSharedPreferences).
///
/// All reads/writes are synchronous but cheap.
final class TokenStore: @unchecked Sendable {

    private static let service = "com.example.givememycoffee.auth"
    private static let keyAccess = "access_token"
    private static let keyRefresh = "refresh_token"
    private static let keyInstalled = "auth.installed"

    private let lock = NSLock()

    init() {
        // Keychain items survive an uninstall, unlike Android's app-private storage.
        // Drop tokens left behind by a previous install so a fresh install starts signed out.
        let defaults = UserDefaults.standard
        if !defaults.bool(forKey: Self.keyInstalled) {
            clear()
            defaults.set(true, forKey: Self.keyInstalled)
        }
    }

    var accessToken: String? {
        get { read(Self.keyAccess) }
        set { write(Self.keyAccess, newValue) }
    }

    var refreshToken: String? {
        get { read(Self.keyRefresh) }
        set { write(Self.keyRefresh, newValue) }
    }

    func save(access: String, refresh: String) {
        write(Self.keyAccess, access)
        write(Self.keyRefresh, refresh)
    }

    func clear() {
        write(Self.keyAccess, nil)
        write(Self.keyRefresh, nil)
    }

    var hasTokens: Bool {
        !(accessToken ?? "").isBlank && !(refreshToken ?? "").isBlank
    }

    // MARK: Keychain

    private func baseQuery(_ account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: account
        ]
    }

    private func read(_ account: String) -> String? {
        lock.lock()
        defer { lock.unlock() }

        var query = baseQuery(account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func write(_ account: String, _ value: String?) {
        lock.lock()
        defer { lock.unlock() }

        let query = baseQuery(account)
        SecItemDelete(query as CFDictionary)
        guard let value else { return }

        var item = query
        item[kSecValueData as String] = Data(value.utf8)
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(item as CFDictionary, nil)
    }
}
