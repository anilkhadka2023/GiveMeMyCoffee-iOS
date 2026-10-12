import Foundation

struct UserProfile: Equatable {
    // Captured at sign up
    var salutation = ""
    var firstName = ""
    var middleName = ""
    var lastName = ""
    var email = ""
    var mobile = ""
    var dateOfBirth = ""
    // Coffee preferences
    var cupName = ""
    var usualMilk: Milk = .fullCream
    // Notifications
    var orderUpdates = true
    var offersByEmail = false
    var smsAlerts = false
    var memberSince: Date?

    var fullName: String {
        [salutation, firstName, middleName, lastName]
            .filter { !$0.isBlank }
            .joined(separator: " ")
    }

    var initials: String {
        let letters = [firstName, lastName].compactMap { $0.trimmed.first?.uppercased() }.joined()
        return letters.isEmpty ? "?" : letters
    }

    // Name the barista calls out; falls back to the first name.
    var displayCupName: String { cupName.ifBlank(firstName) }
}
