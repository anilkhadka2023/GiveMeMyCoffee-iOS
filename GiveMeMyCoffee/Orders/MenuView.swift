import SwiftUI

/// The café menu (OrdersActivity on Android).
struct MenuView: View {
    @State private var viewModel = OrderViewModel()
    let onViewOrder: () -> Void

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if let cafe = viewModel.cafe {
                    CafeHeroCard(name: cafe.name)
                    StatusRow(cafe: cafe)
                    InfoLine(cafe: cafe)
                }
                ForEach(viewModel.menu) { item in
                    MenuItemRow(item: item, onAdd: { viewModel.addItem(id: item.id) })
                    HDivider()
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Palette.orderBackground)
        .safeAreaInset(edge: .bottom) {
            if viewModel.itemCount > 0 {
                ViewOrderButton(itemCount: viewModel.itemCount, total: viewModel.total, onTap: onViewOrder)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.toggleFavourite()
                } label: {
                    Image(systemName: viewModel.isFavourite ? "heart.fill" : "heart")
                        .foregroundStyle(Palette.textDark)
                }
                .accessibilityLabel(viewModel.isFavourite ? "Remove from favourites" : "Add to favourites")
            }
        }
        .task { await viewModel.load() }
    }
}

private struct CafeHeroCard: View {
    let name: String

    var body: some View {
        Text(name)
            .font(.system(size: 24, weight: .bold))
            .foregroundStyle(.white)
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 150, maxHeight: 150, alignment: .bottomLeading)
            .background(
                LinearGradient(
                    colors: [Palette.heroLight, Palette.heroDark],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 20)
            )
    }
}

private struct StatusRow: View {
    let cafe: Cafe

    var body: some View {
        HStack(spacing: 12) {
            if cafe.isTakingOrders {
                TakingOrdersPill(
                    text: "Taking orders · ready in ~\(cafe.readyInMinutes) min",
                    fontSize: 13,
                    dotSize: 8,
                    horizontalPadding: 12
                )
            }
            Text("Open until\n\(cafe.openUntil)")
                .font(.system(size: 13))
                .foregroundStyle(Palette.textGrey)
        }
        .padding(.top, 16)
    }
}

private struct InfoLine: View {
    let cafe: Cafe

    var body: some View {
        Text(attributed)
            .font(.system(size: 13))
            .foregroundStyle(Palette.textGrey)
            .tint(Palette.textGrey)
            .lineSpacing(4)
            .padding(.top, 12)
            .padding(.bottom, 8)
    }

    private var attributed: AttributedString {
        var text = AttributedString("\(cafe.address) · ")
        var directions = AttributedString("Directions")
        directions.link = directionsURL(for: cafe.address)
        directions.underlineStyle = .single
        text.append(directions)
        text.append(AttributedString(" · \(cafe.milkOptions)"))
        return text
    }
}

private struct MenuItemRow: View {
    let item: MenuItem
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Palette.textDark)
                Text(item.description)
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.textGrey)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(formatPrice(item.price))
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Palette.textDark)

            if item.soldOut {
                Text("Sold out")
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.textGrey)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Palette.soldOutBackground, in: Capsule())
            } else {
                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Palette.coffeeBrown, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add \(item.name)")
            }
        }
        .padding(.vertical, 12)
    }
}

private struct ViewOrderButton: View {
    let itemCount: Int
    let total: Double
    let onTap: () -> Void

    var body: some View {
        let itemLabel = itemCount == 1 ? "item" : "items"
        Button("View order · \(itemCount) \(itemLabel) · \(formatPrice(total))", action: onTap)
            .buttonStyle(PillButtonStyle(background: Palette.coffeeBrown, height: 56, font: .system(size: 17, weight: .bold)))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Palette.orderBackground)
    }
}

#Preview {
    NavigationStack {
        MenuView(onViewOrder: {})
    }
}
