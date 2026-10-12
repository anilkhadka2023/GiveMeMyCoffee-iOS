import SwiftUI

struct ProfileView: View {
    @Environment(AppSession.self) private var session
    @State private var viewModel = ProfileViewModel()
    @State private var showDatePicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ProfileHeader(profile: viewModel.profile)

                    SectionLabel(text: "Personal details")
                    if viewModel.isEditing {
                        personalDetailsForm
                    } else {
                        PersonalDetails(profile: viewModel.profile)
                    }

                    SectionLabel(text: "Coffee preferences")
                    coffeePreferences

                    SectionLabel(text: "Notifications")
                    notifications

                    SectionLabel(text: "Account")
                    account

                    signOutButton.padding(.top, 20)

                    if !APIConfig.appVersion.isEmpty {
                        Text("Version \(APIConfig.appVersion)")
                            .font(.system(size: 12))
                            .foregroundStyle(Palette.textGrey)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Palette.orderBackground)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !viewModel.isEditing {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Edit") { viewModel.startEditing() }
                            .fontWeight(.semibold)
                            .foregroundStyle(Palette.coffeeBrown)
                    }
                }
            }
            .sheet(isPresented: $showDatePicker) {
                DateOfBirthSheet(initial: viewModel.draft.dateOfBirth) { viewModel.draft.dateOfBirth = $0 }
            }
        }
    }

    // MARK: Personal details

    private var personalDetailsForm: some View {
        let errors = viewModel.errors
        return OutlinedCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Salutation")
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.textGrey)
                FlowLayout {
                    ForEach(ProfileViewModel.salutations, id: \.self) { option in
                        Chip(label: option, selected: viewModel.draft.salutation == option) {
                            viewModel.draft.salutation = option
                        }
                    }
                }
                if errors.salutation {
                    Text("Please select a salutation")
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.errorRed)
                }

                LabeledField(
                    label: "First name",
                    text: $viewModel.draft.firstName,
                    error: errors.firstName ? "First name is required" : nil,
                    capitalization: .words
                )
                LabeledField(
                    label: "Middle name",
                    text: $viewModel.draft.middleName,
                    capitalization: .words
                )
                LabeledField(
                    label: "Last name",
                    text: $viewModel.draft.lastName,
                    error: errors.lastName ? "Last name is required" : nil,
                    capitalization: .words
                )
                LabeledField(
                    label: "Email",
                    text: $viewModel.draft.email,
                    error: errors.email ? "Enter a valid email address" : nil,
                    keyboard: .emailAddress
                )
                LabeledField(
                    label: "Mobile number",
                    text: $viewModel.draft.mobile,
                    error: errors.mobile ? "Enter a valid 10-15 digit mobile number" : nil,
                    keyboard: .phonePad
                )
                TappableField(
                    label: "Date of birth",
                    value: viewModel.draft.dateOfBirth,
                    placeholder: "DD/MM/YYYY",
                    error: errors.dateOfBirth ? "Use DD/MM/YYYY format" : nil,
                    onTap: { showDatePicker = true }
                )

                HStack(spacing: 12) {
                    Button("Cancel") { viewModel.cancelEditing() }
                        .buttonStyle(PillButtonStyle(
                            background: Palette.soldOutBackground,
                            foreground: Palette.textDark,
                            height: 48,
                            font: .system(size: 15, weight: .semibold)
                        ))
                    Button("Save") {
                        if viewModel.saveEditing() {
                            ToastCenter.shared.show("Profile updated")
                        }
                    }
                    .buttonStyle(PillButtonStyle(background: Palette.coffeeBrown, height: 48, font: .system(size: 15, weight: .bold)))
                }
                .padding(.top, 8)
            }
        }
    }

    // MARK: Preferences

    private var coffeePreferences: some View {
        let profile = viewModel.profile
        let cupName = Binding(
            get: { viewModel.profile.cupName },
            set: { value in viewModel.updatePreferences { $0.cupName = value } }
        )
        return OutlinedCard {
            LabeledField(
                label: "Name for the cup",
                text: cupName,
                placeholder: profile.firstName.ifBlank("Your name"),
                capitalization: .words
            )
            Text("Usual milk")
                .font(.system(size: 12))
                .foregroundStyle(Palette.textGrey)
                .padding(.top, 12)
                .padding(.bottom, 4)
            FlowLayout {
                ForEach(Milk.allCases, id: \.self) { milk in
                    let surcharge = milk.surcharge > 0 ? " +\(formatPrice(milk.surcharge))" : ""
                    Chip(label: milk.label.capitalizedFirst + surcharge, selected: profile.usualMilk == milk) {
                        viewModel.updatePreferences { $0.usualMilk = milk }
                    }
                }
            }
            Text("Used when you tap + on a menu. You can still change it per order.")
                .font(.system(size: 12))
                .foregroundStyle(Palette.textGrey)
                .lineSpacing(4)
                .padding(.top, 4)
        }
    }

    private var notifications: some View {
        let profile = viewModel.profile
        return OutlinedCard {
            ToggleRow(
                title: "Order updates",
                subtitle: "When your coffee is being made and ready",
                isOn: profile.orderUpdates,
                onChange: { isOn in viewModel.updatePreferences { $0.orderUpdates = isOn } }
            )
            RowDivider()
            ToggleRow(
                title: "Offers & news by email",
                subtitle: "New cafés, loyalty rewards and specials",
                isOn: profile.offersByEmail,
                onChange: { isOn in viewModel.updatePreferences { $0.offersByEmail = isOn } }
            )
            RowDivider()
            ToggleRow(
                title: "SMS alerts",
                subtitle: "A text when your order is ready",
                isOn: profile.smsAlerts,
                onChange: { isOn in viewModel.updatePreferences { $0.smsAlerts = isOn } }
            )
        }
    }

    // MARK: Account

    private var account: some View {
        let labels = ["Change password", "Payment methods", "Privacy & terms", "Help & support"]
        return OutlinedCard {
            ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
                if index > 0 { RowDivider() }
                Button {
                    ToastCenter.shared.show("\(label) is coming soon")
                } label: {
                    HStack {
                        Text(label)
                            .font(.system(size: 15))
                            .foregroundStyle(Palette.textDark)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Palette.textGrey)
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var signOutButton: some View {
        Button {
            Task { await viewModel.signOut(session: session) }
        } label: {
            Group {
                if viewModel.isSigningOut {
                    ProgressView().tint(Palette.coffeeBrown)
                } else {
                    Text("Sign out")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Palette.coffeeBrown)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .overlay(Capsule().stroke(Palette.coffeeBrown, lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isSigningOut)
    }
}

private struct SectionLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Palette.textDark)
            .padding(.top, 20)
            .padding(.bottom, 8)
    }
}

private struct RowDivider: View {
    var body: some View {
        HDivider().padding(.vertical, 10)
    }
}

private struct ProfileHeader: View {
    let profile: UserProfile

    private static let memberSinceFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM yyyy")
        return formatter
    }()

    var body: some View {
        OutlinedCard {
            HStack(spacing: 14) {
                Text(profile.initials)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 64, height: 64)
                    .background(Palette.coffeeBrown, in: Circle())
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 0) {
                    Text(profile.fullName.ifBlank("Complete your profile"))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Palette.textDark)
                    if !profile.email.isBlank {
                        Text(profile.email)
                            .font(.system(size: 13))
                            .foregroundStyle(Palette.textGrey)
                    }
                    if let memberSince = profile.memberSince {
                        Text("Member since " + Self.memberSinceFormatter.string(from: memberSince))
                            .font(.system(size: 12))
                            .foregroundStyle(Palette.textGrey)
                            .padding(.top, 2)
                    }
                }
            }
        }
    }
}

private struct PersonalDetails: View {
    let profile: UserProfile

    var body: some View {
        OutlinedCard {
            DetailRow(label: "Name", value: profile.fullName)
            RowDivider()
            DetailRow(label: "Email", value: profile.email)
            RowDivider()
            DetailRow(label: "Mobile", value: profile.mobile)
            RowDivider()
            DetailRow(label: "Date of birth", value: profile.dateOfBirth)
        }
    }
}

private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(Palette.textGrey)
            Text(value.ifBlank("Not set"))
                .font(.system(size: 15))
                .foregroundStyle(value.isBlank ? Palette.textGrey : Palette.textDark)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ToggleRow: View {
    let title: String
    let subtitle: String
    let isOn: Bool
    let onChange: (Bool) -> Void

    var body: some View {
        Toggle(isOn: Binding(get: { isOn }, set: onChange)) {
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.system(size: 15))
                    .foregroundStyle(Palette.textDark)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.textGrey)
            }
        }
        .tint(Palette.coffeeBrown)
    }
}

#Preview {
    ProfileView()
        .environment(AppSession())
}
