import Foundation

/// Minimal URLSession wrapper shared by the API services (the HttpURLConnection plumbing on Android).
enum HTTP {
    struct Response {
        let code: Int
        let body: String

        var isSuccess: Bool { (200..<300).contains(code) }
    }

    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.waitsForConnectivity = false
        return URLSession(configuration: config)
    }()

    static func send(
        _ method: String,
        url: URL,
        body: Data? = nil,
        headers: [String: String] = [:]
    ) async throws -> Response {
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
        }
        for (field, value) in headers {
            request.setValue(value, forHTTPHeaderField: field)
        }

        let (data, response) = try await session.data(for: request)
        let code = (response as? HTTPURLResponse)?.statusCode ?? -1
        return Response(code: code, body: String(decoding: data, as: UTF8.self))
    }

    /// Same wording the Android app uses for ConnectException / SocketTimeoutException / UnknownHostException.
    static func describe(_ error: Error) -> String {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut:
                return "Server timed out. Please try again."
            case .cannotFindHost, .dnsLookupFailed:
                return "Server unreachable: \(urlError.localizedDescription)"
            case .cannotConnectToHost, .networkConnectionLost, .notConnectedToInternet:
                return "Could not connect to server: \(urlError.localizedDescription)"
            default:
                break
            }
        }
        return "Unexpected error: \(error.localizedDescription)"
    }
}
