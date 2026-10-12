import Foundation

/// Thin client for Google Places API (New) `places:searchNearby`.
///
/// Docs: https://developers.google.com/maps/documentation/places/web-service/nearby-search
enum PlacesApiService {

    enum PlacesResult {
        case success([NearbyCafe])
        case error(String)
    }

    private static let endpoint = URL(string: "https://places.googleapis.com/v1/places:searchNearby")!

    // Request only what we render/filter.
    private static let fieldMask = [
        "places.id",
        "places.displayName",
        "places.formattedAddress",
        "places.rating",
        "places.userRatingCount",
        "places.location",
        "places.types",
        "places.priceLevel"
    ].joined(separator: ",")

    static func searchNearbyCafes(
        latitude: Double,
        longitude: Double,
        radiusMeters: Double = 2_000,
        maxResults: Int = 20,
        includedTypes: [String] = ["cafe"]
    ) async -> PlacesResult {
        let apiKey = APIConfig.placesAPIKey
        if apiKey.isEmpty {
            return .error("Missing PLACES_API_KEY. Add it to Config/Secrets.xcconfig and rebuild.")
        }

        var seen = Set<String>()
        let uniqueTypes = includedTypes.filter { !$0.isBlank && seen.insert($0).inserted }
        let center: JSONObject = ["latitude": latitude, "longitude": longitude]
        let circle: JSONObject = ["center": center, "radius": min(max(radiusMeters, 1), 50_000)]
        let body: JSONObject = [
            "includedTypes": uniqueTypes.isEmpty ? ["cafe"] : uniqueTypes,
            "maxResultCount": min(max(maxResults, 1), 20),
            "locationRestriction": ["circle": circle] as JSONObject,
            "rankPreference": "DISTANCE"
        ]

        do {
            let response = try await HTTP.send(
                "POST",
                url: endpoint,
                body: JSON.data(body),
                headers: [
                    "Content-Type": "application/json",
                    "X-Goog-Api-Key": apiKey,
                    "X-Goog-FieldMask": fieldMask
                ]
            )

            guard response.isSuccess else {
                let message = (JSON.object(response.body)?["error"] as? JSONObject)?.optString("message") ?? ""
                return .error(
                    message.isBlank
                        ? "Places API request failed (\(response.code))."
                        : "Places API \(response.code): \(message)"
                )
            }
            return .success(parseCafes(response.body))
        } catch {
            return .error(error.localizedDescription)
        }
    }

    private static func parseCafes(_ json: String) -> [NearbyCafe] {
        guard let places = JSON.object(json)?["places"] as? [JSONObject] else { return [] }

        return places.compactMap { place in
            let name = (place["displayName"] as? JSONObject)?.optString("text") ?? ""
            guard !name.isBlank else { return nil }

            let location = place["location"] as? JSONObject
            return NearbyCafe(
                id: place.optString("id").ifBlank(UUID().uuidString),
                name: name,
                address: place.optString("formattedAddress"),
                rating: place["rating"] as? Double ?? 0,
                latitude: location?["latitude"] as? Double,
                longitude: location?["longitude"] as? Double,
                types: (place["types"] as? [String] ?? []).map(\.trimmed).filter { !$0.isEmpty },
                priceLevel: priceLevel(place.optString("priceLevel"))
            )
        }
    }

    private static func priceLevel(_ value: String) -> Int? {
        switch value {
        case "PRICE_LEVEL_FREE": 0
        case "PRICE_LEVEL_INEXPENSIVE": 1
        case "PRICE_LEVEL_MODERATE": 2
        case "PRICE_LEVEL_EXPENSIVE": 3
        case "PRICE_LEVEL_VERY_EXPENSIVE": 4
        default: nil
        }
    }
}
