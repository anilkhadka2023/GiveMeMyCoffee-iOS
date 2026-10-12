import SwiftUI

@main
struct GiveMeMyCoffeeApp: App {
    @State private var session = AppSession()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
                .toastOverlay()
                .tint(Palette.coffeePrimary)
                .preferredColorScheme(.light)
        }
    }
}

/// Signed-in users skip straight to the app; everyone else lands on log in.
struct RootView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        if session.isLoggedIn {
            MainTabView()
        } else {
            NavigationStack {
                LoginView()
            }
        }
    }
}
