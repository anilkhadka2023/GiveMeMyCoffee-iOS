import Foundation

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }

    var isBlank: Bool { trimmed.isEmpty }

    func ifBlank(_ fallback: @autoclosure () -> String) -> String {
        isBlank ? fallback() : self
    }

    /// "full cream" -> "Full cream"
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }

    func equalsIgnoringCase(_ other: String) -> Bool {
        caseInsensitiveCompare(other) == .orderedSame
    }
}

typealias JSONObject = [String: Any]

enum JSON {
    static func object(_ text: String) -> JSONObject? {
        guard let data = text.data(using: .utf8) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? JSONObject
    }

    static func data(_ object: JSONObject) throws -> Data {
        try JSONSerialization.data(withJSONObject: object)
    }
}

extension Dictionary where Key == String, Value == Any {
    /// Mirrors org.json's `optString`: empty when missing or not a scalar.
    func optString(_ key: String) -> String {
        switch self[key] {
        case let value as String: return value
        case let value as NSNumber: return value.stringValue
        default: return ""
        }
    }
}
