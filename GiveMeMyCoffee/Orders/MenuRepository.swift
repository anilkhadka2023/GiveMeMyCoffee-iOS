import Foundation

// Hardcoded menu for now; swap these bodies for an API call once a menu endpoint exists.
struct MenuRepository {

    func cafe() async -> Cafe {
        Cafe(
            name: "Little Bean",
            isTakingOrders: true,
            readyInMinutes: 4,
            openUntil: "3:00 pm",
            address: "12 Crown St, Surry Hills",
            milkOptions: "Oat, soy, almond, lactose-free"
        )
    }

    func menu() async -> [MenuItem] {
        [
            MenuItem(id: "flat_white", name: "Flat white", description: "Double ristretto, silky milk", price: 5.00),
            MenuItem(id: "long_black", name: "Long black", description: "Two shots over hot water", price: 4.50, hasMilk: false),
            MenuItem(id: "magic", name: "Magic", description: "Double ristretto, ¾ latte", price: 5.20),
            MenuItem(id: "piccolo", name: "Piccolo", description: "Ristretto, splash of milk", price: 4.50, soldOut: true),
            MenuItem(id: "iced_latte", name: "Iced latte", description: "Chilled, over ice", price: 6.00)
        ]
    }
}
