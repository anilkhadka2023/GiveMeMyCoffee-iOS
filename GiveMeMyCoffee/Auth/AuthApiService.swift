import Foundation
import OSLog

struct AuthTokens: Sendable {
    let accessToken: String
    let refreshToken: String
    var tokenType: String = "Bearer"
}

struct LoginResponse: Sendable {
    let userName: String
    var token: AuthTokens
}

enum AuthResult<T: Sendable>: Sendable {
    case success(T)
    case error(message: String, httpCode: Int? = nil)
}

/// Talks directly to the auth endpoints. Only concern here is transport +
/// JSON parsing — token persistence and refresh orchestration live in `AuthRepository`.
enum AuthApiService {

    private static let log = Logger(subsystem: "com.example.givememycoffee", category: "AuthApiService")
    private static let loginPath = "/api/auth/login"
    private static let refreshPath = "/api/auth/refresh"
    private static let logoutPath = "/api/auth/logout"

    static func login(email: String, password: String) async -> AuthResult<LoginResponse> {
        await postForTokens(loginPath, body: ["email": email, "password": password])
    }

    static func refresh(refreshToken: String) async -> AuthResult<LoginResponse> {
        await postForTokens(refreshPath, body: ["refreshToken": refreshToken])
    }

    static func logout(accessToken: String?, refreshToken: String?) async -> AuthResult<Void> {
        var body: JSONObject = [:]
        if let refreshToken, !refreshToken.isBlank { body["refreshToken"] = refreshToken }
        var headers: [String: String] = [:]
        if let accessToken, !accessToken.isBlank { headers["Authorization"] = "Bearer \(accessToken)" }

        let url = APIConfig.url(logoutPath)
        do {
            log.debug("POST \(url.absoluteString)")
            let response = try await HTTP.send("POST", url: url, body: JSON.data(body), headers: headers)
            if response.isSuccess {
                log.debug("Logout response (\(response.code)): \(response.body)")
                return .success(())
            }
            let errorBody = response.body.isEmpty ? "HTTP \(response.code)" : response.body
            log.error("Logout error (\(response.code)): \(errorBody)")
            return .error(message: parseErrorMessage(errorBody) ?? "HTTP \(response.code)", httpCode: response.code)
        } catch {
            return .error(message: HTTP.describe(error))
        }
    }

    private static func postForTokens(_ path: String, body: JSONObject) async -> AuthResult<LoginResponse> {
        let url = APIConfig.url(path)
        do {
            log.debug("POST \(url.absoluteString)")
            let response = try await HTTP.send("POST", url: url, body: JSON.data(body))

            guard response.isSuccess else {
                let errorBody = response.body.isEmpty ? "HTTP \(response.code)" : response.body
                log.error("Error response (\(response.code)): \(errorBody)")
                return .error(message: parseErrorMessage(errorBody) ?? "HTTP \(response.code)", httpCode: response.code)
            }

            guard let json = JSON.object(response.body) else {
                return .error(message: "Unexpected error: invalid JSON in auth response")
            }

            // Tokens can be nested under "token" object or at root level
            let tokenObject = json["token"] as? JSONObject ?? json

            let userName = json.optString("userName").ifBlank(json.optString("username"))
            let accessToken = tokenObject.optString("accessToken").ifBlank(tokenObject.optString("token"))
            let refreshToken = tokenObject.optString("refreshToken")
            let tokenType = tokenObject.optString("tokenType").ifBlank("Bearer")

            if accessToken.isBlank || refreshToken.isBlank {
                log.error("Missing tokens in response: accessToken=\(accessToken.isBlank), refreshToken=\(refreshToken.isBlank)")
                return .error(
                    message: "Unexpected auth response payload (missing accessToken or refreshToken)",
                    httpCode: response.code
                )
            }
            return .success(LoginResponse(
                userName: userName,
                token: AuthTokens(accessToken: accessToken, refreshToken: refreshToken, tokenType: tokenType)
            ))
        } catch {
            return .error(message: HTTP.describe(error))
        }
    }

    private static func parseErrorMessage(_ errorBody: String) -> String? {
        guard let json = JSON.object(errorBody) else { return String(errorBody.prefix(200)) }
        let message = json.optString("message")
        if !message.isBlank { return message }
        let error = json.optString("error")
        return error.isBlank ? nil : error
    }
}
