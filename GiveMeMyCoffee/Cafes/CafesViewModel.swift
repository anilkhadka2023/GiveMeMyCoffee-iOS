import Foundation

/// Nearby cafés with search and filters. Shared by the Home and Cafes tabs, which on Android
/// each had their own copy of this logic.
@MainActor
@Observable
final class CafesViewModel {
    enum LoadState: Equatable {
        case loading
        case ready
        case error(String)
    }

    private(set) var state: LoadState = .loading
    private(set) var allCafes: [NearbyCafe] = []
    var query = ""
    private(set) var appliedFilters = CafeFilters()
    var draftFilters = CafeFilters()
    var showFilterSheet = false

    /// The Cafes tab re-queries Places when filters change; Home only filters what it already has.
    private let refetchOnApply: Bool
    @ObservationIgnored private var hasLoaded = false

    init(refetchOnApply: Bool) {
        self.refetchOnApply = refetchOnApply
    }

    var visibleCafes: [NearbyCafe] { appliedFilters.apply(to: allCafes, query: query) }

    func onAppear() {
        guard !hasLoaded else { return }
        hasLoaded = true
        // Unstructured so switching tabs mid-load doesn't cancel the request.
        Task { await fetch() }
    }

    func retry() {
        Task { await fetch() }
    }

    func openFilters() {
        draftFilters = appliedFilters
        showFilterSheet = true
    }

    func resetDraftFilters() {
        draftFilters = CafeFilters()
    }

    func applyFilters() {
        appliedFilters = draftFilters
        showFilterSheet = false
        if refetchOnApply { retry() }
    }

    private func fetch() async {
        state = .loading
        let coordinate = await LocationProvider.shared.currentCoordinateOrFallback()
        let filters = appliedFilters
        let result = await PlacesApiService.searchNearbyCafes(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            radiusMeters: Double(filters.distanceKm) * 1000,
            maxResults: 20,
            includedTypes: filters.includedPlaceTypes
        )
        switch result {
        case .success(let cafes):
            allCafes = cafes
            state = .ready
        case .error(let message):
            state = .error(message)
        }
    }
}
