import Foundation

enum PickupTime: Equatable {
    case asap
    case scheduled(hour: Int, minute: Int)

    /// Today's date at the scheduled time (nil for ASAP).
    var todayDate: Date? {
        guard case .scheduled(let hour, let minute) = self else { return nil }
        return Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date())
    }
}

@MainActor
@Observable
final class OrderDetailsViewModel {
    private let menuRepository = MenuRepository()
    private let cart: CartRepository
    private let activeOrder: ActiveOrderRepository

    private(set) var cafe: Cafe?
    private(set) var pickup: PickupTime = .asap
    var cupName: String { didSet { showNameError = false } }
    private(set) var showNameError = false
    var editingLine: CartLine?

    init() {
        cart = .shared
        activeOrder = .shared
        cupName = ProfileRepository.shared.profile.displayCupName
    }

    var lines: [CartLine] { cart.lines }

    var subtotal: Double { lines.reduce(0) { $0 + $1.lineTotal } }

    // Australian prices are GST-inclusive, so the GST component is 1/11 of the total.
    var gstIncluded: Double { subtotal / 11 }

    var serviceFees: Double { 0 }

    var total: Double { subtotal + serviceFees }

    func load() async {
        guard cafe == nil else { return }
        cafe = await menuRepository.cafe()
    }

    func selectPickup(_ pickup: PickupTime) {
        self.pickup = pickup
    }

    func startEditing(_ line: CartLine) {
        editingLine = line
    }

    func saveLine(_ line: CartLine) {
        cart.update(line)
        editingLine = nil
    }

    /// Returns true once the order has been placed.
    func placeOrder() -> Bool {
        if cupName.isBlank {
            showNameError = true
            return false
        }
        guard let cafe, !lines.isEmpty else { return false }

        activeOrder.place(cafe: cafe, lines: lines, cupName: cupName, requestedReadyAt: pickup.todayDate)
        cart.clear()
        return true
    }
}
