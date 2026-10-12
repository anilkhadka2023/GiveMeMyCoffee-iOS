import Foundation
import OSLog

struct SignUpRequest {
    let salutation: String
    let firstName: String
    let middleName: String
    let lastName: String
    let email: String
    let mobile: String
    let dateOfBirth: String
    let password: String
    let confirmPassword: String
}

enum SignUpResult {
    case success
    case error(String)
}

enum SignUpApiService {
    private static let log = Logger(subsystem: "com.example.givememycoffee", category: "SignUp")
    private static let registerPath = "/api/Signup/register"

    static func register(_ request: SignUpRequest) async -> SignUpResult {
        let body: JSONObject = [
            "salutation": request.salutation,
            "firstName": request.firstName,
            "middleName": request.middleName,
            "lastName": request.lastName,
            "email": request.email,
            "mobile": request.mobile,
            "dateOfBirth": request.dateOfBirth,
            "password": request.password,
            "confirmPassword": request.confirmPassword
        ]

        do {
            let url = APIConfig.url(registerPath)
            log.debug("Sending sign up request to \(url.absoluteString) for \(request.email)")
            let response = try await HTTP.send("POST", url: url, body: JSON.data(body))
            if response.isSuccess { return .success }

            let errorBody = response.body.isEmpty ? "HTTP \(response.code)" : response.body
            return .error("Registration failed: \(errorBody)")
        } catch {
            return .error("Could not connect to server: \(error.localizedDescription)")
        }
    }
}
