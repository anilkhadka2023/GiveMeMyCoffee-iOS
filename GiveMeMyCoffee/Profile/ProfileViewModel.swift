import Foundation

struct ProfileErrors {
    var salutation = false
    var firstName = false
    var lastName = false
    var email = false
    var mobile = false
    var dateOfBirth = false

    var any: Bool { salutation || firstName || lastName || email || mobile || dateOfBirth }

    // Same rules as the sign up form.
    static func of(_ profile: UserProfile) -> ProfileErrors {
        ProfileErrors(
            salutation: profile.salutation.isBlank,
            firstName: profile.firstName.isBlank,
            lastName: profile.lastName.isBlank,
            email: !isValidSignUpEmail(profile.email),
            mobile: !isValidMobile(profile.mobile),
            dateOfBirth: !isValidDateOfBirth(profile.dateOfBirth)
        )
    }
}

@MainActor
@Observable
final class ProfileViewModel {
    static let salutations = ["Mr", "Mrs", "Ms", "Dr"]

    private let repository: ProfileRepository

    private(set) var isEditing = false
    var draft = UserProfile()
    private(set) var submitAttempted = false
    private(set) var isSigningOut = false

    init() {
        repository = .shared
    }

    var profile: UserProfile { repository.profile }

    var errors: ProfileErrors { submitAttempted ? .of(draft) : ProfileErrors() }

    func startEditing() {
        draft = repository.profile
        submitAttempted = false
        isEditing = true
    }

    func cancelEditing() {
        isEditing = false
        submitAttempted = false
    }

    /// Returns false (and shows the field errors) when the draft is invalid.
    func saveEditing() -> Bool {
        if ProfileErrors.of(draft).any {
            submitAttempted = true
            return false
        }
        // Preferences may have changed while the form was open, so only take the personal details.
        var updated = repository.profile
        updated.salutation = draft.salutation
        updated.firstName = draft.firstName.trimmed
        updated.middleName = draft.middleName.trimmed
        updated.lastName = draft.lastName.trimmed
        updated.email = draft.email.trimmed
        updated.mobile = draft.mobile.trimmed
        updated.dateOfBirth = draft.dateOfBirth
        repository.save(updated)

        isEditing = false
        submitAttempted = false
        return true
    }

    /// Preferences and notification toggles save straight away.
    func updatePreferences(_ transform: (inout UserProfile) -> Void) {
        var updated = repository.profile
        transform(&updated)
        repository.save(updated)
    }

    func signOut(session: AppSession) async {
        guard !isSigningOut else { return }
        isSigningOut = true
        let result = await AuthRepository.shared.logout()
        isSigningOut = false

        if case .error(let message, _) = result {
            ToastCenter.shared.show("Signed out on this device. Server sign-out failed: \(message)", long: true)
        }
        session.didSignOut()
    }
}
