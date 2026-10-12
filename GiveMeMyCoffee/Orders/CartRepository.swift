import Foundation

// In-memory cart shared by the menu and order details screens for the app session.
@MainActor
@Observable
final class CartRepository {
    static let shared = CartRepository()

    private(set) var lines: [CartLine] = []
    @ObservationIgnored private var nextId: Int64 = 1

    func add(_ item: MenuItem, milk: Milk = .fullCream) {
        if let index = lines.firstIndex(where: {
            $0.item.id == item.id && $0.size == .regular && $0.milk == milk && $0.sugar == .zero
        }) {
            lines[index].quantity += 1
        } else {
            lines.append(CartLine(id: nextId, item: item, milk: milk))
            nextId += 1
        }
    }

    func update(_ line: CartLine) {
        if line.quantity <= 0 {
            lines.removeAll { $0.id == line.id }
        } else if let index = lines.firstIndex(where: { $0.id == line.id }) {
            lines[index] = line
        }
    }

    func clear() {
        lines = []
    }
}
