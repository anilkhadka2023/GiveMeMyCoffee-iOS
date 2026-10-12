import Foundation

// Field rules shared by log in, sign up and the profile editor.

/// Same pattern as Android's `Patterns.EMAIL_ADDRESS`.
func isValidSignUpEmail(_ email: String) -> Bool {
    let pattern = #"^[A-Za-z0-9+._%\-]{1,256}@[A-Za-z0-9][A-Za-z0-9\-]{0,64}(\.[A-Za-z0-9][A-Za-z0-9\-]{0,25})+$"#
    return email.trimmed.range(of: pattern, options: .regularExpression) != nil
}

func isValidMobile(_ mobileNumber: String) -> Bool {
    let digits = mobileNumber.filter(\.isNumber)
    return (10...15).contains(digits.count)
}

func isValidDateOfBirth(_ dateOfBirth: String) -> Bool {
    let pattern = #"^(0[1-9]|[12][0-9]|3[01])/(0[1-9]|1[0-2])/\d{4}$"#
    return dateOfBirth.trimmed.range(of: pattern, options: .regularExpression) != nil
}

/// DD/MM/YYYY, the format the backend expects for date of birth.
enum DateOfBirthFormat {
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }()

    static func string(from date: Date) -> String { formatter.string(from: date) }

    static func date(from string: String) -> Date? { formatter.date(from: string.trimmed) }
}
