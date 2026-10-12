import Foundation

/// Thin wrapper for making authenticated HTTP calls.
///
///  - Automatically attaches `Authorization: Bearer <accessToken>`.
///  - Proactively refreshes an expired token before sending.
///  - On a 401 response, forces one refresh + retry.
///  - If the refresh ultimately fails, returns `.unauthorized`
///    so callers can send the user back to the login screen.
///
/// Use this for any protected endpoint beyond /auth/login and /auth/refresh.
struct AuthenticatedApiClient {

    enum ApiResponse {
        case success(code: Int, body: String)
        case httpError(code: Int, body: String)
        case unauthorized
        case networkError(String)
    }

    let authRepository: AuthRepository

    init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }

    func get(_ path: String) async -> ApiResponse { await request("GET", path, jsonBody: nil) }

    func post(_ path: String, jsonBody: String) async -> ApiResponse { await request("POST", path, jsonBody: jsonBody) }

    func put(_ path: String, jsonBody: String) async -> ApiResponse { await request("PUT", path, jsonBody: jsonBody) }

    func delete(_ path: String) async -> ApiResponse { await request("DELETE", path, jsonBody: nil) }

    private func request(_ method: String, _ path: String, jsonBody: String?) async -> ApiResponse {
        guard let token = await authRepository.validAccessToken() else { return .unauthorized }

        let first = await execute(method, path, jsonBody: jsonBody, bearer: token)
        guard case .httpError(401, _) = first else { return first }

        // 401 despite our best guess of a valid token — try a forced refresh once.
        guard let fresh = await authRepository.forceRefresh() else { return .unauthorized }
        return await execute(method, path, jsonBody: jsonBody, bearer: fresh)
    }

    private func execute(_ method: String, _ path: String, jsonBody: String?, bearer: String) async -> ApiResponse {
        do {
            let response = try await HTTP.send(
                method,
                url: APIConfig.url(path),
                body: jsonBody.map { Data($0.utf8) },
                headers: ["Authorization": "Bearer \(bearer)"]
            )
            return response.isSuccess
                ? .success(code: response.code, body: response.body)
                : .httpError(code: response.code, body: response.body)
        } catch {
            return .networkError(error.localizedDescription)
        }
    }
}
