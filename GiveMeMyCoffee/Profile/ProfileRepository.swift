import Foundation

/// Keeps the signed-in user's profile on the device. There's no profile endpoint yet, so this is
/// filled from the sign up form and topped up at login.
@MainActor
@Observable
final class ProfileRepository {
    static let shared = ProfileRepository()

    private(set) var profile: UserProfile
    private let defaults: UserDefaults

    private enum Key {
        static let salutation = "user_profile.salutation"
        static let firstName = "user_profile.first_name"
        static let middleName = "user_profile.middle_name"
        static let lastName = "user_profile.last_name"
        static let email = "user_profile.email"
        static let mobile = "user_profile.mobile"
        static let dateOfBirth = "user_profile.date_of_birth"
        static let cupName = "user_profile.cup_name"
        static let usualMilk = "user_profile.usual_milk"
        static let orderUpdates = "user_profile.order_updates"
        static let offersByEmail = "user_profile.offers_email"
        static let smsAlerts = "user_profile.sms_alerts"
        static let memberSince = "user_profile.member_since"

        static let all = [
            salutation, firstName, middleName, lastName, email, mobile, dateOfBirth,
            cupName, usualMilk, orderUpdates, offersByEmail, smsAlerts, memberSince
        ]
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        profile = Self.load(from: defaults)
    }

    func save(_ profile: UserProfile) {
        defaults.set(profile.salutation, forKey: Key.salutation)
        defaults.set(profile.firstName, forKey: Key.firstName)
        defaults.set(profile.middleName, forKey: Key.middleName)
        defaults.set(profile.lastName, forKey: Key.lastName)
        defaults.set(profile.email, forKey: Key.email)
        defaults.set(profile.mobile, forKey: Key.mobile)
        defaults.set(profile.dateOfBirth, forKey: Key.dateOfBirth)
        defaults.set(profile.cupName, forKey: Key.cupName)
        defaults.set(profile.usualMilk.rawValue, forKey: Key.usualMilk)
        defaults.set(profile.orderUpdates, forKey: Key.orderUpdates)
        defaults.set(profile.offersByEmail, forKey: Key.offersByEmail)
        defaults.set(profile.smsAlerts, forKey: Key.smsAlerts)
        defaults.set(profile.memberSince?.timeIntervalSince1970 ?? 0, forKey: Key.memberSince)
        self.profile = profile
    }

    /// Stores the details entered on the sign up form.
    func saveFromSignUp(
        salutation: String,
        firstName: String,
        middleName: String,
        lastName: String,
        email: String,
        mobile: String,
        dateOfBirth: String
    ) {
        save(UserProfile(
            salutation: salutation,
            firstName: firstName.trimmed,
            middleName: middleName.trimmed,
            lastName: lastName.trimmed,
            email: email.trimmed,
            mobile: mobile.trimmed,
            dateOfBirth: dateOfBirth,
            memberSince: Date()
        ))
    }

    /// Fills gaps from the login response; never overwrites details the user already has.
    func mergeFromLogin(email: String, userName: String) {
        let email = email.trimmed
        let current = profile
        if current.email.equalsIgnoringCase(email) && !current.firstName.isBlank { return }

        let sameUser = current.email.isBlank || current.email.equalsIgnoringCase(email)
        var updated = sameUser ? current : UserProfile()
        updated.email = email
        updated.firstName = updated.firstName.ifBlank(userName.trimmed)
        updated.memberSince = updated.memberSince ?? Date()
        save(updated)
    }

    func clear() {
        Key.all.forEach { defaults.removeObject(forKey: $0) }
        profile = UserProfile()
    }

    private static func load(from defaults: UserDefaults) -> UserProfile {
        let memberSince = defaults.double(forKey: Key.memberSince)
        return UserProfile(
            salutation: defaults.string(forKey: Key.salutation) ?? "",
            firstName: defaults.string(forKey: Key.firstName) ?? "",
            middleName: defaults.string(forKey: Key.middleName) ?? "",
            lastName: defaults.string(forKey: Key.lastName) ?? "",
            email: defaults.string(forKey: Key.email) ?? "",
            mobile: defaults.string(forKey: Key.mobile) ?? "",
            dateOfBirth: defaults.string(forKey: Key.dateOfBirth) ?? "",
            cupName: defaults.string(forKey: Key.cupName) ?? "",
            usualMilk: defaults.string(forKey: Key.usualMilk).flatMap(Milk.init(rawValue:)) ?? .fullCream,
            orderUpdates: defaults.object(forKey: Key.orderUpdates) as? Bool ?? true,
            offersByEmail: defaults.bool(forKey: Key.offersByEmail),
            smsAlerts: defaults.bool(forKey: Key.smsAlerts),
            memberSince: memberSince > 0 ? Date(timeIntervalSince1970: memberSince) : nil
        )
    }
}
