import Foundation

@MainActor
@Observable
final class OrderStatusViewModel {
    private let repository: ActiveOrderRepository
    private(set) var now = Date()

    init() {
        repository = .shared
    }

    var order: PlacedOrder? { repository.order }

    var status: OrderStatus? { order?.status(at: now) }

    /// Ticks once a second while the screen is visible so the simulated status advances.
    func runClock() async {
        while !Task.isCancelled {
            now = Date()
            try? await Task.sleep(for: .seconds(1))
        }
    }

    func onPrimaryAction() {
        switch status {
        case .received, .beingMade: repository.markArrived()
        case .ready: repository.markCollected()
        case .collected, nil: break
        }
    }

    func onRunningLate() {
        repository.runningLate()
        ToastCenter.shared.show("No rush — we've pushed your order back 5 min")
    }

    func onContact() {
        ToastCenter.shared.show("Contacting the café is coming soon")
    }
}
