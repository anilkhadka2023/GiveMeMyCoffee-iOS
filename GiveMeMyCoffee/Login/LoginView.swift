import SwiftUI

struct LoginView: View {
    @Environment(AppSession.self) private var session
    @State private var viewModel = LoginViewModel()
    @State private var showSignUp = false

    var body: some View {
        CenteredCardScroll {
            VStack(spacing: 0) {
                header
                form.padding(.top, 24)

                if let serverError = viewModel.serverError {
                    Text(serverError)
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.serverError)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                }

                actions.padding(.top, 16)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showSignUp) {
            SignUpView()
        }
    }

    private var header: some View {
        VStack(spacing: 0) {
            Image("CoffeeIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .accessibilityLabel("Coffee app logo")
            Text("Welcome Back")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Palette.coffeePrimary)
                .padding(.top, 16)
            Text("Sign in to get your coffee")
                .font(.system(size: 14))
                .foregroundStyle(Palette.coffeeSecondary)
        }
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: 12) {
            LabeledField(
                label: "Email",
                text: $viewModel.email,
                error: viewModel.emailError ? "Enter a valid email address" : nil,
                keyboard: .emailAddress,
                contentType: .username
            )
            LabeledField(
                label: "Password",
                text: $viewModel.password,
                error: viewModel.passwordError ? "Password must be at least 6 characters" : nil,
                isSecure: !viewModel.passwordVisible,
                contentType: .password
            )
            TextLinkButton(title: viewModel.passwordVisible ? "Hide password" : "Show password") {
                viewModel.passwordVisible.toggle()
            }
        }
    }

    private var actions: some View {
        HStack(spacing: 12) {
            Button {
                Task { await viewModel.logIn(session: session) }
            } label: {
                if viewModel.isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text("Log in")
                }
            }
            .buttonStyle(PillButtonStyle(background: Palette.coffeePrimary, font: .system(size: 15, weight: .medium)))
            .disabled(viewModel.isLoading)

            Button("Sign up") { showSignUp = true }
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Palette.coffeePrimary)
                .frame(maxWidth: .infinity, minHeight: 52)
                .buttonStyle(.plain)
                .disabled(viewModel.isLoading)
        }
    }
}

/// White rounded card centred on the coffee background, scrolling when the keyboard is up.
struct CenteredCardScroll<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                content
                    .padding(24)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 24))
                    .padding(24)
                    .frame(maxWidth: .infinity, minHeight: geo.size.height)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(Palette.coffeeBackground.ignoresSafeArea())
    }
}

#Preview {
    NavigationStack {
        LoginView()
    }
    .environment(AppSession())
}
