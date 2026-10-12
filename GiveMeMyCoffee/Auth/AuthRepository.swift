import Foundation
import OSLog

/// Single entry point for authentication state.
///
/// Responsibilities:
///  - Log in with email/password and persist tokens.
///  - Provide a *valid* access token to callers, transparently refreshing
///    when the current one is expired / near-expiry.
///  - Serialize concurrent refreshes so parallel API calls only trigger ONE
///    refresh round-trip (the actor plus a shared in-flight task replace the Kotlin Mutex).
///  - Log out (clear tokens).
actor AuthRepository {

    static let shared = AuthRepository()

    private static let log = Logger(subsystem: "com.example.givememycoffee", category: "AuthRepository")

    private let tokenStore: TokenStore
    private var refreshTask: Task<String?, Never>?

    init(tokenStore: TokenStore = TokenStore()) {
        self.tokenStore = tokenStore
    }

    /// True iff we have both tokens persisted. Cheap to call.
    nonisolated var isLoggedIn: Bool { tokenStore.hasTokens }

    func login(email: String, password: String) async -> AuthResult<LoginResponse> {
        let result = await AuthApiService.login(email: email.trimmed, password: password)
        if case .success(let response) = result {
            tokenStore.save(access: response.token.accessToken, refresh: response.token.refreshToken)
        }
        return result
    }

    func logout() async -> AuthResult<Void> {
        let access = tokenStore.accessToken
        let refresh = tokenStore.refreshToken

        let remoteResult: AuthResult<Void>
        if (access ?? "").isBlank && (refresh ?? "").isBlank {
            remoteResult = .success(())
        } else {
            remoteResult = await AuthApiService.logout(accessToken: access, refreshToken: refresh)
        }

        // Always clear local tokens to complete sign-out on this device.
        tokenStore.clear()
        return remoteResult
    }

    /// Returns an access token that is currently valid, refreshing if needed.
    /// Returns nil if the user isn't logged in or the refresh failed (caller should route to log in).
    func validAccessToken() async -> String? {
        if let current = tokenStore.accessToken, !JwtUtils.isExpired(current) { return current }
        return await refreshSerialized(force: false)
    }

    /// Called by `AuthenticatedApiClient` after a 401 to force a refresh.
    func forceRefresh() async -> String? {
        await refreshSerialized(force: true)
    }

    private func refreshSerialized(force: Bool) async -> String? {
        // Another caller is already refreshing: wait for its result instead of starting a second one.
        if let refreshTask { return await refreshTask.value }

        let task = Task { await self.performRefresh(force: force) }
        refreshTask = task
        let token = await task.value
        refreshTask = nil
        return token
    }

    private func performRefresh(force: Bool) async -> String? {
        // Re-check: another caller may have refreshed while we were waiting.
        if !force, let latest = tokenStore.accessToken, !JwtUtils.isExpired(latest) { return latest }

        guard let refresh = tokenStore.refreshToken else { return nil }
        switch await AuthApiService.refresh(refreshToken: refresh) {
        case .success(let response):
            tokenStore.save(access: response.token.accessToken, refresh: response.token.refreshToken)
            return response.token.accessToken
        case .error(let message, let httpCode):
            let code = httpCode.map { String($0) } ?? "nil"
            Self.log.warning("Refresh failed (\(code)): \(message)")
            // 401/403 on refresh => refresh token is dead. Force logout.
            if httpCode == 401 || httpCode == 403 { tokenStore.clear() }
            return nil
        }
    }
}
