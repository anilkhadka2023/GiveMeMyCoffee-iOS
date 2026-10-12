import SwiftUI

struct OrderDetailsView: View {
    @State private var viewModel = OrderDetailsViewModel()
    @State private var showTimePicker = false
    let onOrderPlaced: () -> Void

    var body: some View {
        Group {
            if viewModel.lines.isEmpty {
                Text("Your order is empty")
                    .font(.system(size: 16))
                    .foregroundStyle(Palette.textGrey)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    content.padding(.horizontal, 16)
                }
                .scrollDismissesKeyboard(.interactively)
                .safeAreaInset(edge: .bottom) {
                    PaymentBar(
                        cafeName: viewModel.cafe?.name ?? "",
                        onPay: {
                            if viewModel.placeOrder() { onOrderPlaced() }
                        }
                    )
                }
            }
        }
        .background(Palette.orderBackground)
        .navigationTitle("Your order")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $showTimePicker) {
            TimePickerSheet { hour, minute in
                viewModel.selectPickup(.scheduled(hour: hour, minute: minute))
            }
        }
        .sheet(item: $viewModel.editingLine) { line in
            EditLineSheet(line: line, onSave: { viewModel.saveLine($0) })
        }
        .environment(\.openURL, OpenURLAction { url in
            switch url.absoluteString {
            case PaymentBar.cardLink:
                ToastCenter.shared.show("Card payments coming soon")
                return .handled
            case PaymentBar.policyLink:
                ToastCenter.shared.show("Refunds are handled by \(viewModel.cafe?.name ?? "the cafe")")
                return .handled
            default:
                return .systemAction
            }
        })
        .task { await viewModel.load() }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let cafe = viewModel.cafe {
                OrderSummaryCard(cafe: cafe, lines: viewModel.lines, onEdit: { viewModel.startEditing($0) })
                    .padding(.top, 8)
            }

            SectionLabel(text: "Pickup").padding(.top, 18)
            PickupSelector(
                pickup: viewModel.pickup,
                readyInMinutes: viewModel.cafe?.readyInMinutes ?? 0,
                onSelectAsap: { viewModel.selectPickup(.asap) },
                onPickTime: { showTimePicker = true }
            )
            Text(viewModel.pickup == .asap
                 ? "Made when you're close — not left on the bench. Change to “I'm here” any time."
                 : "We'll start making it a few minutes before your pickup time.")
                .font(.system(size: 12))
                .foregroundStyle(Palette.textGrey)
                .lineSpacing(4)
                .padding(.top, 8)

            SectionLabel(text: "Name for the cup").padding(.top, 18)
            CupNameField(name: $viewModel.cupName, showError: viewModel.showNameError)

            Totals(viewModel: viewModel)
                .padding(.bottom, 16)
        }
    }
}

private struct SectionLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Palette.textDark)
            .padding(.bottom, 8)
    }
}

private struct OrderSummaryCard: View {
    let cafe: Cafe
    let lines: [CartLine]
    let onEdit: (CartLine) -> Void

    var body: some View {
        OutlinedCard {
            HStack {
                Text(cafe.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Palette.textDark)
                Spacer()
                if cafe.isTakingOrders {
                    TakingOrdersPill(text: "Taking orders")
                }
            }
            HDivider().padding(.vertical, 12)
            VStack(alignment: .leading, spacing: 12) {
                ForEach(lines) { line in
                    CartLineRow(line: line, onEdit: { onEdit(line) })
                }
            }
        }
    }
}

private struct CartLineRow: View {
    let line: CartLine
    let onEdit: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(description)
                    .font(.system(size: 14))
                    .lineSpacing(4)
                Button(action: onEdit) {
                    Text("Edit")
                        .font(.system(size: 12))
                        .underline()
                        .foregroundStyle(Palette.textGrey)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Edit \(line.item.name)")
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(formatPrice(line.lineTotal))
                .font(.system(size: 14))
                .foregroundStyle(Palette.textDark)
        }
    }

    private var description: AttributedString {
        var name = AttributedString("\(line.quantity) × \(line.item.name)")
        name.foregroundColor = Palette.textDark
        var options = AttributedString(" · \(line.optionsLabel)")
        options.foregroundColor = Palette.textGrey
        return name + options
    }
}

private struct PickupSelector: View {
    let pickup: PickupTime
    let readyInMinutes: Int
    let onSelectAsap: () -> Void
    let onPickTime: () -> Void

    var body: some View {
        let readyAt = formatClock(Date().addingTimeInterval(TimeInterval(readyInMinutes * 60)))
        HStack(spacing: 0) {
            segment("ASAP · ready at \(readyAt)", selected: pickup == .asap, action: onSelectAsap)
            segment(scheduledLabel ?? "Pick a time", selected: pickup != .asap, action: onPickTime)
        }
        .frame(height: 40)
        .overlay(Capsule().stroke(Palette.coffeeBrown, lineWidth: 1))
    }

    private var scheduledLabel: String? {
        guard let date = pickup.todayDate else { return nil }
        return "At " + formatClockWithPeriod(date)
    }

    private func segment(_ text: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 13, weight: selected ? .semibold : .regular))
                .foregroundStyle(Palette.textDark)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(selected ? Palette.soldOutBackground : Color.clear, in: Capsule())
                .padding(1)
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

private struct CupNameField: View {
    @Binding var name: String
    let showError: Bool
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField("Your name", text: $name)
                .focused($focused)
                .textInputAutocapitalization(.words)
                .foregroundStyle(Palette.textDark)
                .tint(Palette.coffeeBrown)
                .padding(.horizontal, 16)
                .frame(height: 56)
                .background(
                    Palette.inputBackground,
                    in: UnevenRoundedRectangle(topLeadingRadius: 4, topTrailingRadius: 4)
                )
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(showError ? Palette.errorRed : (focused ? Palette.coffeeBrown : Palette.divider))
                        .frame(height: focused || showError ? 2 : 1)
                }
            if showError {
                Text("Add a name so the barista knows it's yours")
                    .font(.caption)
                    .foregroundStyle(Palette.errorRed)
                    .padding(.horizontal, 16)
            }
        }
    }
}

private struct Totals: View {
    let viewModel: OrderDetailsViewModel

    var body: some View {
        VStack(spacing: 0) {
            HDivider().padding(.top, 16).padding(.bottom, 8)
            TotalRow(label: "Subtotal", value: formatPrice(viewModel.subtotal), color: Palette.textDark)
            TotalRow(label: "GST included", value: formatPrice(viewModel.gstIncluded), color: Palette.textGrey)
            TotalRow(
                label: "Service fees · surcharges",
                value: formatPrice(viewModel.serviceFees),
                color: Palette.statusGreen,
                weight: .medium
            )
            HDivider().padding(.vertical, 8)
            TotalRow(label: "Total", value: formatPrice(viewModel.total), color: .black, size: 17, weight: .bold)
        }
    }
}

private struct TotalRow: View {
    let label: String
    let value: String
    let color: Color
    var size: CGFloat = 13
    var weight: Font.Weight = .regular

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
        }
        .font(.system(size: size, weight: weight))
        .foregroundStyle(color)
        .padding(.vertical, 4)
    }
}

private struct PaymentBar: View {
    static let cardLink = "givememycoffee-action://card"
    static let policyLink = "givememycoffee-action://policy"

    let cafeName: String
    let onPay: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HDivider()
            // Stand-in wallet button: like the "Google Pay" button on Android it places the order
            // without taking a payment.
            Button(action: onPay) {
                HStack(spacing: 4) {
                    Image(systemName: "apple.logo")
                    Text("Pay")
                }
            }
            .buttonStyle(PillButtonStyle(background: .black, font: .system(size: 17, weight: .semibold)))
            .padding(.horizontal, 16)
            .padding(.top, 12)

            Text(footer)
                .font(.system(size: 12))
                .foregroundStyle(Palette.textGrey)
                .tint(Palette.textGrey)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
        }
        .background(Color.white)
    }

    private var footer: AttributedString {
        var text = AttributedString("or ")
        text.append(link("pay with a card", to: Self.cardLink))
        text.append(AttributedString(" · Refunds by \(cafeName) · "))
        text.append(link("Policy", to: Self.policyLink))
        return text
    }

    private func link(_ label: String, to url: String) -> AttributedString {
        var text = AttributedString(label)
        text.link = URL(string: url)
        text.underlineStyle = .single
        return text
    }
}
