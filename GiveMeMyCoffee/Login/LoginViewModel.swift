import Foundation

@MainActor
@Observable
final class LoginViewModel {
    var email = "" { didSet { serverError = nil } }
    var password = "" { didSet { serverError = nil } }
    var passwordVisible = false
    private(set) var submitAttempted = false
    private(set) var isLoading = false
    private(set) var serverError: String?

    var emailError: Bool { submitAttempted && !isValidSignUpEmail(email) }
    var passwordError: Bool { submitAttempted && password.count < 6 }

    func logIn(session: AppSession) async {
        submitAttempted = true
        guard isValidSignUpEmail(email), password.count >= 6, !isLoading else { return }

        isLoading = true
        serverError = nil
        let result = await AuthRepository.shared.login(email: email, password: password)
        isLoading = false

        switch result {
        case .success(let response):
            ProfileRepository.shared.mergeFromLogin(email: email, userName: response.userName)
            ToastCenter.shared.show("Welcome back!")
            session.didLogIn(userName: response.userName)
        case .error(let message, let httpCode):
            serverError = (httpCode == 401 || httpCode == 403) ? "Invalid email or password." : message
        }
    }
}
