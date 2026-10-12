import SwiftUI

struct CafesView: View {
    @State private var viewModel = CafesViewModel(refetchOnApply: true)

    var body: some View {
        NavigationStack {
            CafeListSection(
                viewModel: viewModel,
                searchPlaceholder: "Restaurant name or dish...",
                horizontalPadding: 16,
                header: "List of cafes"
            )
            .background(Palette.coffeeBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Cafes")
                        .font(.headline)
                        .foregroundStyle(Palette.coffeePrimary)
                }
            }
            .toolbarBackground(Color.white, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}
