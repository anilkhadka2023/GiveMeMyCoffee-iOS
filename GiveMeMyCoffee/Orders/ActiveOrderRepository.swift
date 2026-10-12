import Foundation

enum OrderStatus: Int, CaseIterable, Comparable {
    case received
    case beingMade
    case ready
    case collected

    var label: String {
        switch self {
        case .received: "Received"
        case .beingMade: "Being made"
        case .ready: "Ready"
        case .collected: "Collected"
        }
    }

    static func < (lhs: OrderStatus, rhs: OrderStatus) -> Bool { lhs.rawValue < rhs.rawValue }
}

struct PlacedOrder: Hashable {
    let number: String
    let cafe: Cafe
    let lines: [CartLine]
    let cupName: String
    var startAt: Date
    var readyAt: Date
    var customerArrived = false
    var collected = false

    func status(at now: Date) -> OrderStatus {
        if collected { return .collected }
        if now >= readyAt { return .ready }
        if now >= startAt { return .beingMade }
        return .received
    }
}

// In-memory store for the order currently in progress. The status is simulated from the
// clock until there's a backend to report it.
@MainActor
@Observable
final class ActiveOrderRepository {
    static let shared = ActiveOrderRepository()

    private static let makeDuration: TimeInterval = 3 * 60

    private(set) var order: PlacedOrder?

    func place(cafe: Cafe, lines: [CartLine], cupName: String, requestedReadyAt: Date?) {
        let now = Date()
        let earliestReady = now.addingTimeInterval(TimeInterval(cafe.readyInMinutes * 60))
        let readyAt = max(requestedReadyAt ?? earliestReady, earliestReady)
        order = PlacedOrder(
            number: "A\(Int.random(in: 10..<100))",
            cafe: cafe,
            lines: lines,
            cupName: cupName.trimmed,
            startAt: max(now, readyAt.addingTimeInterval(-Self.makeDuration)),
            readyAt: readyAt
        )
    }

    func markArrived() {
        order?.customerArrived = true
    }

    func markCollected() {
        order?.collected = true
    }

    func runningLate(minutes: Int = 5) {
        guard var order else { return }
        let now = Date()
        guard order.status(at: now) < .ready else { return }

        let delay = TimeInterval(minutes * 60)
        // Don't un-start an order the barista is already making.
        if now < order.startAt {
            order.startAt = order.startAt.addingTimeInterval(delay)
        }
        order.readyAt = order.readyAt.addingTimeInterval(delay)
        order.customerArrived = false
        self.order = order
    }
}
