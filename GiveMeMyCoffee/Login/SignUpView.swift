import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = SignUpViewModel()
    @State private var showDatePicker = false

    var body: some View {
        CenteredCardScroll {
            VStack(alignment: .leading, spacing: 10) {
                VStack(spacing: 0) {
                    Text("Create Account")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(Palette.coffeePrimary)
                    Text("Join and start your coffee journey")
                        .font(.system(size: 14))
                        .foregroundStyle(Palette.coffeeSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
                .padding(.bottom, 8)

                fields

                if let apiError = viewModel.apiError {
                    Text(apiError)
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.serverError)
                        .padding(.top, 6)
                }

                actions.padding(.top, 6)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showDatePicker) {
            DateOfBirthSheet(initial: viewModel.dateOfBirth) { viewModel.dateOfBirth = $0 }
        }
    }

    @ViewBuilder
    private var fields: some View {
        nameFields
        contactFields
        passwordFields
    }

    @ViewBuilder
    private var nameFields: some View {
        SelectField(
            label: "Salutation",
            value: viewModel.salutation,
            options: SignUpViewModel.salutations,
            error: viewModel.salutationError ? "Please select a salutation" : nil,
            onSelect: { viewModel.salutation = $0 }
        )
        LabeledField(
            label: "First name",
            text: $viewModel.firstName,
            error: viewModel.firstNameError ? "First name is required" : nil,
            capitalization: .words,
            contentType: .givenName
        )
        LabeledField(
            label: "Middle name",
            text: $viewModel.middleName,
            capitalization: .words,
            contentType: .middleName
        )
        LabeledField(
            label: "Last name",
            text: $viewModel.lastName,
            error: viewModel.lastNameError ? "Last name is required" : nil,
            capitalization: .words,
            contentType: .familyName
        )
    }

    @ViewBuilder
    private var contactFields: some View {
        LabeledField(
            label: "Email",
            text: $viewModel.email,
            error: viewModel.emailError ? "Enter a valid email address" : nil,
            keyboard: .emailAddress,
            contentType: .emailAddress
        )
        LabeledField(
            label: "Mobile number",
            text: $viewModel.mobileNumber,
            error: viewModel.mobileError ? "Enter a valid 10-15 digit mobile number" : nil,
            keyboard: .phonePad,
            contentType: .telephoneNumber
        )
        TappableField(
            label: "Date of birth",
            value: viewModel.dateOfBirth,
            placeholder: "DD/MM/YYYY",
            error: viewModel.dateOfBirthError ? "Use DD/MM/YYYY format" : nil,
            onTap: { showDatePicker = true }
        )
    }

    @ViewBuilder
    private var passwordFields: some View {
        LabeledField(
            label: "Password",
            text: $viewModel.password,
            error: viewModel.passwordError ? "Password must be at least 6 characters" : nil,
            isSecure: !viewModel.passwordVisible,
            contentType: .newPassword
        )
        visibilityToggle(isVisible: viewModel.passwordVisible) { viewModel.passwordVisible.toggle() }
        LabeledField(
            label: "Confirm password",
            text: $viewModel.confirmPassword,
            error: viewModel.confirmPasswordError ? "Passwords do not match" : nil,
            isSecure: !viewModel.confirmPasswordVisible,
            contentType: .newPassword
        )
        visibilityToggle(isVisible: viewModel.confirmPasswordVisible) { viewModel.confirmPasswordVisible.toggle() }
    }

    private func visibilityToggle(isVisible: Bool, action: @escaping () -> Void) -> some View {
        TextLinkButton(title: isVisible ? "Hide password" : "Show password", action: action)
            .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private var actions: some View {
        HStack(spacing: 12) {
            Button("Log in") { dismiss() }
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Palette.coffeePrimary)
                .frame(maxWidth: .infinity, minHeight: 52)
                .buttonStyle(.plain)
                .disabled(viewModel.isLoading)

            Button {
                Task {
                    if await viewModel.signUp() { dismiss() }
                }
            } label: {
                if viewModel.isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text("Sign up")
                }
            }
            .buttonStyle(PillButtonStyle(background: Palette.coffeePrimary, font: .system(size: 15, weight: .medium)))
            .disabled(viewModel.isLoading)
        }
    }
}

#Preview {
    NavigationStack {
        SignUpView()
    }
}
