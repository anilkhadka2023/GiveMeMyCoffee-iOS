import SwiftUI

enum AppTab: Hashable {
    case home, cafes, orders, profile
}

/// The bottom navigation shared by every signed-in screen (`CoffeeBottomBar` on Android).
struct MainTabView: View {
    @State private var selection: AppTab = .home

    var body: some View {
        TabView(selection: $selection) {
            HomeView(onOpenProfile: { selection = .profile })
                .whiteTabBar()
                .tabItem { Label("Home", systemImage: "house") }
                .tag(AppTab.home)

            CafesView()
                .whiteTabBar()
                .tabItem { Label("Cafes", systemImage: "cup.and.saucer") }
                .tag(AppTab.cafes)

            OrdersTab()
                .whiteTabBar()
                .tabItem { Label("Orders", systemImage: "list.bullet.rectangle") }
                .tag(AppTab.orders)

            ProfileView()
                .whiteTabBar()
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                .tag(AppTab.profile)
        }
        .tint(Palette.coffeePrimary)
    }
}

enum OrdersRoute: Hashable {
    case details
    case status
}

/// Menu -> order details -> order status, all inside the Orders tab.
struct OrdersTab: View {
    @State private var path: [OrdersRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            MenuView(onViewOrder: { path.append(.details) })
                .navigationDestination(for: OrdersRoute.self) { route in
                    switch route {
                    case .details:
                        // Placing the order replaces the details screen with the status screen.
                        OrderDetailsView(onOrderPlaced: { path = [.status] })
                    case .status:
                        OrderStatusView()
                    }
                }
        }
    }
}

private extension View {
    func whiteTabBar() -> some View {
        toolbarBackground(Color.white, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
    }
}
