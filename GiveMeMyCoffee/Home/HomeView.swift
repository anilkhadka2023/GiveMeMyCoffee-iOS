import SwiftUI

struct HomeView: View {
    @Environment(AppSession.self) private var session
    @State private var viewModel = HomeViewModel()
    let onOpenProfile: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 8) {
                UsualOrderCard()

                Text("Cafés near you")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Palette.coffeePrimary)
                    .padding(.leading, 8)
                    .padding(.top, 16)

                // Scrollable list of cafés (same logic as the Cafes tab, including search)
                CafeListSection(
                    viewModel: viewModel.cafes,
                    searchPlaceholder: "Search cafés or suburbs...",
                    horizontalPadding: 8
                )
                .background(Palette.coffeeBackground)
            }
            .padding(16)
            .background(Color.white)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 12) {
                        menu
                        Text("Good morning \(viewModel.greetingName(session: session))!")
                            .font(.headline)
                            .foregroundStyle(Palette.coffeePrimary)
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Palette.sunYellow)
                            .accessibilityLabel("Good morning sun")
                    }
                }
            }
            .toolbarBackground(Color.white, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .alert("Log out?", isPresented: $viewModel.showLogoutConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Log out", role: .destructive) {
                    Task { await viewModel.logOut(session: session) }
                }
            } message: {
                Text("You'll need to log in again to order coffee.")
            }
        }
    }

    /// The navigation drawer from the Android app, as a toolbar menu.
    private var menu: some View {
        Menu {
            Button { viewModel.comingSoon("Settings") } label: {
                Label("Settings", systemImage: "gearshape")
            }
            Button(action: onOpenProfile) {
                Label("Profile", systemImage: "person")
            }
            Button { viewModel.comingSoon("About") } label: {
                Label("About", systemImage: "info.circle")
            }
            Divider()
            Button(role: .destructive) { viewModel.showLogoutConfirm = true } label: {
                Label("Log out", systemImage: "power")
            }
        } label: {
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(Palette.coffeePrimary)
        }
        .accessibilityLabel("Open menu")
    }
}

/// "Your usual" reorder card.
private struct UsualOrderCard: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("YOUR USUAL - LITTLE BEAN")
                .font(.system(size: 12, weight: .bold))
            Text("Flat white, regular - A$5.70")
                .font(.system(size: 16, weight: .bold))
            Text("Taking orders - ready in ~3 minutes")
                .font(.system(size: 16, weight: .bold))
            // Reorder isn't wired up yet (it was a no-op on Android too).
            Button("Reorder") {}
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.gray)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white, in: Capsule())
                .buttonStyle(.plain)
        }
        .foregroundStyle(.white)
        .multilineTextAlignment(.center)
        .padding(.vertical, 8)
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Palette.coffeePrimary, in: RoundedRectangle(cornerRadius: 24))
        .padding(24)
        .background(Palette.coffeeBackground)
    }
}
