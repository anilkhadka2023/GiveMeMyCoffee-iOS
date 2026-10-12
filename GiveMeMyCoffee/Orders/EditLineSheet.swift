import SwiftUI

/// Quantity, size, milk and sugar for one cart line (the edit dialog on Android).
struct EditLineSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: CartLine
    private let line: CartLine
    private let onSave: (CartLine) -> Void

    init(line: CartLine, onSave: @escaping (CartLine) -> Void) {
        self.line = line
        self.onSave = onSave
        _draft = State(initialValue: line)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    quantityRow

                    OptionGroup(
                        title: "Size",
                        options: CupSize.allCases,
                        selected: draft.size,
                        label: { $0.label.capitalizedFirst + surchargeLabel($0.surcharge) },
                        onSelect: { draft.size = $0 }
                    )
                    if line.item.hasMilk {
                        OptionGroup(
                            title: "Milk",
                            options: Milk.allCases,
                            selected: draft.milk,
                            label: { $0.label.capitalizedFirst + surchargeLabel($0.surcharge) },
                            onSelect: { draft.milk = $0 }
                        )
                    }
                    OptionGroup(
                        title: "Sugar",
                        options: Sugar.allCases,
                        selected: draft.sugar,
                        label: { $0.label.capitalizedFirst },
                        onSelect: { draft.sugar = $0 }
                    )

                    actions.padding(.top, 24)
                }
                .padding(20)
            }
            .background(Palette.orderBackground)
            .navigationTitle(line.item.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Palette.textGrey)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var quantityRow: some View {
        HStack {
            Text("Quantity").foregroundStyle(Palette.textDark)
            Spacer()
            stepButton("−", label: "Decrease quantity") { draft.quantity = max(draft.quantity - 1, 1) }
            Text("\(draft.quantity)")
                .foregroundStyle(Palette.textDark)
                .frame(minWidth: 32)
            stepButton("+", label: "Increase quantity") { draft.quantity += 1 }
        }
    }

    private var actions: some View {
        HStack(spacing: 12) {
            Button("Remove") {
                var removed = draft
                removed.quantity = 0
                onSave(removed)
            }
            .buttonStyle(PillButtonStyle(
                background: Palette.soldOutBackground,
                foreground: Palette.errorRed,
                height: 48,
                font: .system(size: 15, weight: .semibold)
            ))

            Button("Save · \(formatPrice(draft.lineTotal))") { onSave(draft) }
                .buttonStyle(PillButtonStyle(background: Palette.coffeeBrown, height: 48, font: .system(size: 15, weight: .bold)))
        }
    }

    private func stepButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(symbol)
                .foregroundStyle(Palette.textDark)
                .frame(width: 32, height: 32)
                .overlay(Circle().stroke(Color.gray.opacity(0.5), lineWidth: 1))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func surchargeLabel(_ surcharge: Double) -> String {
        surcharge > 0 ? " +\(formatPrice(surcharge))" : ""
    }
}

private struct OptionGroup<Option: Hashable>: View {
    let title: String
    let options: [Option]
    let selected: Option
    let label: (Option) -> String
    let onSelect: (Option) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .fontWeight(.semibold)
                .foregroundStyle(Palette.textDark)
                .padding(.top, 16)
            FlowLayout {
                ForEach(options, id: \.self) { option in
                    Chip(label: label(option), selected: option == selected) { onSelect(option) }
                }
            }
        }
    }
}
