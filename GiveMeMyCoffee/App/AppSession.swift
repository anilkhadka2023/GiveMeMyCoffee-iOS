import Foundation

/// Whether the user is signed in, which decides between the login flow and the main tabs.
/// Replaces the Android activity hops (LoginActivity <-> MainActivity with CLEAR_TOP flags).
@MainActor
@Observable
final class AppSession {
    private(set) var isLoggedIn: Bool
    /// The name returned by the last login (the "userName" intent extra on Android).
    private(set) var userName: String?

    init() {
        isLoggedIn = AuthRepository.shared.isLoggedIn
    }

    func didLogIn(userName: String) {
        self.userName = userName
        isLoggedIn = true
    }

    func didSignOut() {
        userName = nil
        isLoggedIn = false
    }
}
