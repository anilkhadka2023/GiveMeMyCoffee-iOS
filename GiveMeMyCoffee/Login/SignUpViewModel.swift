import Foundation

@MainActor
@Observable
final class SignUpViewModel {
    static let salutations = ["Mr", "Mrs", "Ms", "Dr"]

    var salutation = ""
    var firstName = ""
    var middleName = ""
    var lastName = ""
    var email = ""
    var mobileNumber = ""
    var dateOfBirth = ""
    var password = ""
    var confirmPassword = ""
    var passwordVisible = false
    var confirmPasswordVisible = false
    private(set) var submitAttempted = false
    private(set) var isLoading = false
    private(set) var apiError: String?

    var salutationError: Bool { submitAttempted && salutation.isBlank }
    var firstNameError: Bool { submitAttempted && firstName.isBlank }
    var lastNameError: Bool { submitAttempted && lastName.isBlank }
    var emailError: Bool { submitAttempted && !isValidSignUpEmail(email) }
    var mobileError: Bool { submitAttempted && !isValidMobile(mobileNumber) }
    var dateOfBirthError: Bool { submitAttempted && !isValidDateOfBirth(dateOfBirth) }
    var passwordError: Bool { submitAttempted && password.count < 6 }
    var confirmPasswordError: Bool { submitAttempted && confirmPassword != password }

    private var hasErrors: Bool {
        salutationError || firstNameError || lastNameError || emailError ||
            mobileError || dateOfBirthError || passwordError || confirmPasswordError
    }

    /// Returns true once the account is created, so the screen can go back to log in.
    func signUp() async -> Bool {
        submitAttempted = true
        apiError = nil
        guard !hasErrors, !isLoading else { return false }

        isLoading = true
        defer { isLoading = false }

        let result = await SignUpApiService.register(SignUpRequest(
            salutation: salutation,
            firstName: firstName,
            middleName: middleName,
            lastName: lastName,
            email: email,
            mobile: mobileNumber,
            dateOfBirth: dateOfBirth,
            password: password,
            confirmPassword: confirmPassword
        ))

        switch result {
        case .success:
            ProfileRepository.shared.saveFromSignUp(
                salutation: salutation,
                firstName: firstName,
                middleName: middleName,
                lastName: lastName,
                email: email,
                mobile: mobileNumber,
                dateOfBirth: dateOfBirth
            )
            return true
        case .error(let message):
            apiError = message
            return false
        }
    }
}
