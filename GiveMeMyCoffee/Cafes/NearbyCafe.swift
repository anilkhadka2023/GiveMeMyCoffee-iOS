import Foundation

/// A café returned by Google Places (`Cafe` in the Android CafesActivity).
struct NearbyCafe: Identifiable, Hashable {
    let id: String
    let name: String
    let address: String
    let rating: Double
    var latitude: Double?
    var longitude: Double?
    var types: [String] = []
    var priceLevel: Int?
}

struct CafeFilters: Equatable {
    static let categoryLabels = ["Fast food", "European", "Italian", "Mexican", "Japanese", "French"]
    static let priceBounds: ClosedRange<Double> = 0...200

    var selectedCategories: Set<String> = []
    var distanceKm = 2
    var selectedRatings: Set<Int> = []
    var priceRange: ClosedRange<Double> = CafeFilters.priceBounds

    /// Places API types to request: always cafés, plus the chosen cuisines.
    var includedPlaceTypes: [String] {
        let extra = Self.categoryLabels
            .filter { selectedCategories.contains($0) }
            .compactMap(Self.placeType(for:))
        return ["cafe"] + extra
    }

    /// Search box and filters applied on the device to the fetched results.
    func apply(to cafes: [NearbyCafe], query: String) -> [NearbyCafe] {
        cafes.filter { cafe in
            let matchesQuery = query.isBlank ||
                cafe.name.localizedCaseInsensitiveContains(query) ||
                cafe.address.localizedCaseInsensitiveContains(query)

            let matchesCategory = selectedCategories.isEmpty || selectedCategories.contains { label in
                if label == "European" {
                    return cafe.types.contains("european_restaurant") ||
                        cafe.name.localizedCaseInsensitiveContains("european") ||
                        cafe.address.localizedCaseInsensitiveContains("european")
                }
                guard let type = Self.placeType(for: label) else { return false }
                return cafe.types.contains(type)
            }

            let matchesRating = selectedRatings.isEmpty ||
                (cafe.rating > 0 && selectedRatings.contains(min(max(Int(cafe.rating), 1), 5)))

            let matchesPrice = cafe.priceLevel.map { priceRange.contains(Self.estimatedPrice(forLevel: $0)) } ?? true

            return matchesQuery && matchesCategory && matchesRating && matchesPrice
        }
    }

    private static func placeType(for label: String) -> String? {
        switch label {
        case "Fast food": "fast_food_restaurant"
        case "Italian": "italian_restaurant"
        case "Mexican": "mexican_restaurant"
        case "Japanese": "japanese_restaurant"
        case "French": "french_restaurant"
        default: nil
        }
    }

    private static func estimatedPrice(forLevel level: Int) -> Double {
        switch level {
        case 1: 20
        case 2: 55
        case 3: 95
        case 4: 140
        default: 0
        }
    }
}
