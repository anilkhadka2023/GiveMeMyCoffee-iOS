import Foundation

/// Minimal JWT decoding helpers. We only care about the `exp` (expiration)
/// claim so we can proactively refresh a nearly-expired access token.
///
/// We intentionally do NOT verify the signature client-side — that's the
/// server's job. This is only used to decide *when* to refresh.
enum JwtUtils {

    /// Returns the token's `exp` claim (seconds since epoch), or nil if it can't be parsed.
    static func expiryEpochSeconds(_ jwt: String?) -> Int64? {
        guard let jwt, !jwt.isBlank else { return nil }
        let parts = jwt.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count >= 2 else { return nil }

        var base64 = parts[1]
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }

        guard let data = Data(base64Encoded: base64),
              let json = (try? JSONSerialization.jsonObject(with: data)) as? JSONObject else { return nil }

        switch json["exp"] {
        case let exp as NSNumber: return exp.int64Value
        case let exp as String: return Int64(exp)
        default: return nil
        }
    }

    /// True if the token is missing, unparsable, or will expire within
    /// `leewaySeconds` (default 30s to cover clock skew + latency).
    static func isExpired(_ jwt: String?, leewaySeconds: Int64 = 30) -> Bool {
        guard let exp = expiryEpochSeconds(jwt) else { return true }
        let now = Int64(Date().timeIntervalSince1970)
        return now + leewaySeconds >= exp
    }
}
