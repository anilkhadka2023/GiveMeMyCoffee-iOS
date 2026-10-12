import CoreLocation

/// One-shot current location with permission prompt (the fused location client on Android).
@MainActor
final class LocationProvider: NSObject, CLLocationManagerDelegate {
    static let shared = LocationProvider()

    // Fallback centre used when location is not available. Coordinates are Melbourne CBD.
    nonisolated static let fallback = CLLocationCoordinate2D(latitude: -37.8168224109326, longitude: 144.96272148310956)

    private let manager = CLLocationManager()
    private var authorizationWaiters: [CheckedContinuation<Void, Never>] = []
    private var locationWaiters: [CheckedContinuation<CLLocationCoordinate2D, Never>] = []

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    /// Asks for permission if it hasn't been decided, then returns the current position,
    /// or the fallback when permission is denied or the fix fails.
    func currentCoordinateOrFallback() async -> CLLocationCoordinate2D {
        if manager.authorizationStatus == .notDetermined {
            await withCheckedContinuation { continuation in
                authorizationWaiters.append(continuation)
                manager.requestWhenInUseAuthorization()
            }
        }

        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return await withCheckedContinuation { continuation in
                locationWaiters.append(continuation)
                if locationWaiters.count == 1 { manager.requestLocation() }
            }
        default:
            return Self.fallback
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            guard status != .notDetermined else { return }
            let waiters = authorizationWaiters
            authorizationWaiters = []
            waiters.forEach { $0.resume() }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let coordinate = locations.last?.coordinate ?? Self.fallback
        Task { @MainActor in finishLocation(coordinate) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in finishLocation(Self.fallback) }
    }

    private func finishLocation(_ coordinate: CLLocationCoordinate2D) {
        let waiters = locationWaiters
        locationWaiters = []
        waiters.forEach { $0.resume(returning: coordinate) }
    }
}
