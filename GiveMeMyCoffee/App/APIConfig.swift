import Foundation

/// App configuration for API endpoints.
/// Update these values to match your local backend setup.
enum APIConfig {
    // The iOS Simulator shares the Mac's network, so 127.0.0.1 reaches a backend running on the
    // Mac directly (no `adb reverse` equivalent needed). On a physical device use the Mac's LAN IP.
    static let baseURL = "http://127.0.0.1:55812"
    // static let baseURL = "https://coffeeapi-fzg2h4abgwd6hnb7.westus3-01.azurewebsites.net"

    static func url(_ path: String) -> URL {
        URL(string: baseURL + path)!
    }

    /// Google Places key, injected from Config/Secrets.xcconfig through Info.plist.
    static var placesAPIKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "PlacesAPIKey") as? String ?? "").trimmed
    }

    static var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }
}
