import Foundation

struct MenuItem: Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let price: Double
    var soldOut = false
    var hasMilk = true
}

/// The café a menu belongs to (not the Google Places result, which is `NearbyCafe`).
struct Cafe: Hashable {
    let name: String
    let isTakingOrders: Bool
    let readyInMinutes: Int
    let openUntil: String
    let address: String
    let milkOptions: String
    var pickupNote = "pickup bench on the left"
}

enum CupSize: String, CaseIterable, Hashable {
    case regular = "Regular"
    case large = "Large"

    var label: String {
        switch self {
        case .regular: "regular"
        case .large: "large"
        }
    }

    var surcharge: Double {
        switch self {
        case .regular: 0
        case .large: 0.80
        }
    }
}

/// Raw values match the Kotlin enum names so stored preferences read the same.
enum Milk: String, CaseIterable, Hashable {
    case fullCream = "FullCream"
    case skim = "Skim"
    case oat = "Oat"
    case soy = "Soy"
    case almond = "Almond"
    case lactoseFree = "LactoseFree"

    var label: String {
        switch self {
        case .fullCream: "full cream"
        case .skim: "skim"
        case .oat: "oat"
        case .soy: "soy"
        case .almond: "almond"
        case .lactoseFree: "lactose-free"
        }
    }

    var surcharge: Double {
        switch self {
        case .fullCream, .skim: 0
        case .oat, .almond: 0.70
        case .soy, .lactoseFree: 0.50
        }
    }
}

enum Sugar: String, CaseIterable, Hashable {
    case zero = "None"
    case one = "One"
    case two = "Two"

    var label: String {
        switch self {
        case .zero: "no sugar"
        case .one: "1 sugar"
        case .two: "2 sugars"
        }
    }
}

struct CartLine: Identifiable, Hashable {
    let id: Int64
    let item: MenuItem
    var size: CupSize = .regular
    var milk: Milk = .fullCream
    var sugar: Sugar = .zero
    var quantity = 1

    var unitPrice: Double {
        item.price + size.surcharge + (item.hasMilk ? milk.surcharge : 0)
    }

    var lineTotal: Double { unitPrice * Double(quantity) }

    var optionsLabel: String {
        [size.label, item.hasMilk ? milk.label : nil, sugar.label]
            .compactMap { $0 }
            .joined(separator: ", ")
    }
}

func formatPrice(_ price: Double) -> String {
    String(format: "A$%.2f", locale: Locale(identifier: "en_US_POSIX"), price)
}

private let clockFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mm"
    return formatter
}()

private let clockWithPeriodFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mm a"
    return formatter
}()

func formatClock(_ date: Date) -> String { clockFormatter.string(from: date) }

func formatClockWithPeriod(_ date: Date) -> String { clockWithPeriodFormatter.string(from: date) }

/// Apple Maps search for an address (the Android app opens Google Maps).
func directionsURL(for address: String) -> URL? {
    let query = address.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
    return URL(string: "https://maps.apple.com/?q=\(query)")
}
