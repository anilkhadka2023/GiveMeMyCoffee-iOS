import SwiftUI

/// Search bar, filter sheet and the café list/loading/error states.
struct CafeListSection: View {
    @Bindable var viewModel: CafesViewModel
    let searchPlaceholder: String
    var horizontalPadding: CGFloat = 16
    var header: String?

    var body: some View {
        VStack(spacing: 0) {
            CafeSearchBar(
                query: $viewModel.query,
                placeholder: searchPlaceholder,
                onFilterTap: { viewModel.openFilters() }
            )
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, header == nil ? 8 : 12)

            if let header {
                Text(header)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Palette.coffeePrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }

            content
        }
        .sheet(isPresented: $viewModel.showFilterSheet) {
            FiltersSheet(
                filters: $viewModel.draftFilters,
                onReset: { viewModel.resetDraftFilters() },
                onApply: { viewModel.applyFilters() }
            )
        }
        .onAppear { viewModel.onAppear() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.large)
                    .tint(Palette.coffeePrimary)
                Text("Finding cafes near you...")
                    .foregroundStyle(Palette.coffeeSecondary)
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .error(let message):
            VStack(spacing: 12) {
                Text(message)
                    .font(.system(size: 14))
                    .foregroundStyle(Palette.coffeePrimary)
                    .multilineTextAlignment(.center)
                Button("Retry") { viewModel.retry() }
                    .buttonStyle(PillButtonStyle(background: Palette.accent, height: 40, font: .system(size: 14, weight: .medium)))
                    .fixedSize()
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .ready:
            let cafes = viewModel.visibleCafes
            if cafes.isEmpty {
                Text(viewModel.allCafes.isEmpty ? "No cafes found nearby." : "No cafes match your filters.")
                    .font(.system(size: 16))
                    .foregroundStyle(Palette.coffeeSecondary)
                    .multilineTextAlignment(.center)
                    .padding(24)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(cafes) { cafe in
                            CafeCard(cafe: cafe)
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, 8)
                }
                .scrollDismissesKeyboard(.immediately)
            }
        }
    }
}

struct CafeSearchBar: View {
    @Binding var query: String
    let placeholder: String
    let onFilterTap: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Palette.coffeeSecondary)
                .accessibilityHidden(true)
            TextField("", text: $query, prompt: Text(placeholder).foregroundStyle(Palette.coffeeSecondary))
                .foregroundStyle(Palette.textDark)
                .autocorrectionDisabled()
                .submitLabel(.search)
            Button(action: onFilterTap) {
                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(Palette.accent)
            }
            .accessibilityLabel("Open filters")
        }
        .padding(.leading, 16)
        .padding(.trailing, 12)
        .frame(height: 56)
        .background(Color.white, in: Capsule())
    }
}

struct CafeCard: View {
    let cafe: NearbyCafe

    var body: some View {
        HStack(spacing: 12) {
            Image("CoffeeIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .frame(width: 64, height: 64)
                .background(Palette.cafeThumbBackground, in: RoundedRectangle(cornerRadius: 12))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center) {
                    Text(cafe.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Palette.coffeePrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if cafe.rating > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(Palette.starYellow)
                            Text(String(format: "%.1f", locale: Locale(identifier: "en_US_POSIX"), cafe.rating))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Palette.coffeePrimary)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Rating \(String(format: "%.1f", cafe.rating))")
                    }
                }
                if !cafe.address.isBlank {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 12))
                            .foregroundStyle(Palette.accent)
                            .accessibilityHidden(true)
                        Text(cafe.address)
                            .font(.system(size: 13))
                            .foregroundStyle(Palette.coffeeSecondary)
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
    }
}
