import SwiftUI

struct FiltersSheet: View {
    @Binding var filters: CafeFilters
    let onReset: () -> Void
    let onApply: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    Text("Filter")
                        .font(.system(size: 28, weight: .bold))
                    HStack {
                        Spacer()
                        TextLinkButton(title: "Reset", color: .gray, action: onReset)
                    }
                }

                sectionTitle("Categories").padding(.top, 12)
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(CafeFilters.categoryLabels, id: \.self) { label in
                        accentChip(label, selected: filters.selectedCategories.contains(label)) {
                            filters.selectedCategories.formSymmetricDifference([label])
                        }
                    }
                }
                .padding(.top, 10)

                sectionTitle("Distance to me").padding(.top, 14)
                HStack(spacing: 4) {
                    Spacer()
                    stepButton("-") { filters.distanceKm = max(filters.distanceKm - 1, 1) }
                        .accessibilityLabel("Decrease distance")
                    Text("\(filters.distanceKm) km")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(Palette.accent)
                    stepButton("+") { filters.distanceKm = min(filters.distanceKm + 1, 50) }
                        .accessibilityLabel("Increase distance")
                }
                .padding(.top, 8)

                sectionTitle("Rating").padding(.top, 8)
                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { star in
                        accentChip("\(star)*", selected: filters.selectedRatings.contains(star)) {
                            filters.selectedRatings.formSymmetricDifference([star])
                        }
                    }
                }
                .padding(.top, 8)

                HStack {
                    sectionTitle("Price")
                    Spacer()
                    Text("$\(Int(filters.priceRange.lowerBound.rounded()))-$\(Int(filters.priceRange.upperBound.rounded()))")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Palette.accent)
                }
                .padding(.top, 10)

                RangeSlider(range: $filters.priceRange, bounds: CafeFilters.priceBounds, tint: Palette.accent)
                    .padding(.top, 4)

                Button("Show results", action: onApply)
                    .buttonStyle(PillButtonStyle(background: Palette.accent, font: .system(size: 18, weight: .medium)))
                    .padding(.top, 8)
            }
            .padding(16)
            .padding(.top, 8)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text).font(.system(size: 22, weight: .bold))
    }

    private func accentChip(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Chip(
            label: label,
            selected: selected,
            selectedBackground: Palette.accent,
            selectedForeground: .white,
            expand: true,
            action: action
        )
    }

    private func stepButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(symbol)
                .font(.system(size: 24))
                .foregroundStyle(.black)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
