import SwiftUI

struct OrderStatusView: View {
    @State private var viewModel = OrderStatusViewModel()

    var body: some View {
        Group {
            if let order = viewModel.order, let status = viewModel.status {
                ScrollView {
                    VStack(spacing: 0) {
                        StatusCard(order: order, status: status)
                        ActionButtons(
                            order: order,
                            status: status,
                            onPrimary: { viewModel.onPrimaryAction() },
                            onRunningLate: { viewModel.onRunningLate() }
                        )
                        PickupCard(order: order)
                        Button { viewModel.onContact() } label: {
                            Text("Something wrong? Contact the café")
                                .font(.system(size: 14))
                                .underline()
                                .foregroundStyle(Palette.coffeeBrown)
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 16)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            } else {
                Text("No active order")
                    .font(.system(size: 16))
                    .foregroundStyle(Palette.textGrey)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Palette.orderBackground)
        .navigationTitle(viewModel.order.map { "Order #\($0.number)" } ?? "Order")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.runClock() }
    }
}

private struct StatusCard: View {
    let order: PlacedOrder
    let status: OrderStatus

    var body: some View {
        OutlinedCard(padding: EdgeInsets(top: 24, leading: 12, bottom: 24, trailing: 12), alignment: .center) {
            Text(formatClock(order.readyAt))
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(Palette.coffeeBrown)
            Text(status.label)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Palette.headingBrown)
                .padding(.top, 4)
            Text(subtitle)
                .font(.system(size: 15))
                .foregroundStyle(Palette.textGrey)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.top, 6)
            StatusStepper(current: status)
                .padding(.top, 20)
        }
    }

    private var subtitle: String {
        switch status {
        case .received, .beingMade:
            order.customerArrived
                ? "The barista knows you're here — it'll be on the bench at \(formatClock(order.readyAt))"
                : "Barista starts at \(formatClock(order.startAt)) so it's fresh when you arrive"
        case .ready:
            "On the \(order.cafe.pickupNote) — look for \(order.cupName.uppercased())"
        case .collected:
            "Enjoy your coffee!"
        }
    }
}

private struct StatusStepper: View {
    let current: OrderStatus

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(OrderStatus.allCases, id: \.self) { step in
                let isCurrent = step == current && current != .collected
                let isDone = step < current || (step == current && current == .collected)
                VStack(spacing: 4) {
                    ZStack {
                        if isCurrent {
                            Circle().fill(Palette.stepCurrentHalo).frame(width: 20, height: 20)
                            Circle().fill(Palette.stepCurrent).frame(width: 13, height: 13)
                        } else if isDone {
                            Circle().fill(Palette.statusGreen).frame(width: 14, height: 14)
                        } else {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 14, height: 14)
                                .overlay(Circle().stroke(Palette.stepPending, lineWidth: 1.5))
                        }
                    }
                    .frame(width: 20, height: 20)

                    Text(step.label)
                        .font(.system(size: 11, weight: isCurrent ? .semibold : .regular))
                        .foregroundStyle(isDone || isCurrent ? Palette.textDark : Palette.textGrey)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityValue(isCurrent ? "Current step" : (isDone ? "Done" : ""))
            }
        }
    }
}

private struct ActionButtons: View {
    let order: PlacedOrder
    let status: OrderStatus
    let onPrimary: () -> Void
    let onRunningLate: () -> Void

    private var inProgress: Bool { status == .received || status == .beingMade }

    private var primaryLabel: String {
        if status == .ready { return "✓ Picked up" }
        if status == .collected { return "✓ Collected" }
        if order.customerArrived { return "✓ On my way in" }
        return "📍 I'm here"
    }

    private var primaryEnabled: Bool {
        status == .ready || (inProgress && !order.customerArrived)
    }

    var body: some View {
        HStack(spacing: 12) {
            Button(primaryLabel, action: onPrimary)
                .buttonStyle(PillButtonStyle(
                    background: Palette.coffeeBrown,
                    disabledBackground: Palette.coffeeBrown.opacity(0.6),
                    disabledForeground: .white
                ))
                .disabled(!primaryEnabled)

            Button("🕒 Running late", action: onRunningLate)
                .buttonStyle(PillButtonStyle(
                    background: Palette.soldOutBackground,
                    foreground: Palette.textDark,
                    disabledBackground: Palette.soldOutBackground.opacity(0.6),
                    disabledForeground: Palette.textGrey,
                    font: .system(size: 16, weight: .semibold)
                ))
                .disabled(!inProgress)
        }
        .padding(.vertical, 14)
    }
}

private struct PickupCard: View {
    let order: PlacedOrder

    var body: some View {
        let cafe = order.cafe
        OutlinedCard {
            HStack {
                Text(cafe.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Palette.textDark)
                Spacer()
                if let url = directionsURL(for: cafe.address) {
                    Link(destination: url) {
                        Text("Directions")
                            .font(.system(size: 14))
                            .underline()
                            .foregroundStyle(Palette.coffeeBrown)
                    }
                }
            }
            Text(pickupLine)
                .font(.system(size: 12))
                .foregroundStyle(Palette.textGrey)
                .lineSpacing(4)
                .padding(.top, 4)
            HDivider().padding(.vertical, 12)
            VStack(alignment: .leading, spacing: 6) {
                ForEach(order.lines) { line in
                    Text("\(line.quantity) × \(line.item.name) · \(line.optionsLabel)")
                        .font(.system(size: 14))
                        .foregroundStyle(Palette.textDark)
                }
            }
        }
    }

    private var pickupLine: AttributedString {
        let street = order.cafe.address.split(separator: ",", maxSplits: 1).first.map(String.init) ?? order.cafe.address
        var text = AttributedString("\(street) · \(order.cafe.pickupNote), look for ")
        var name = AttributedString(order.cupName.uppercased())
        name.font = .system(size: 12, weight: .bold)
        text.append(name)
        return text
    }
}
