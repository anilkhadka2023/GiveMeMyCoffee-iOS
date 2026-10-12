import SwiftUI

/// Full-width capsule button, the equivalent of the Material `Button` used across the app.
struct PillButtonStyle: ButtonStyle {
    var background: Color
    var foreground: Color = .white
    var disabledBackground: Color?
    var disabledForeground: Color?
    var height: CGFloat = 52
    var font: Font = .system(size: 16, weight: .bold)

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(font)
            .multilineTextAlignment(.center)
            .foregroundStyle(isEnabled ? foreground : (disabledForeground ?? foreground))
            .frame(maxWidth: .infinity, minHeight: height)
            .background(
                isEnabled ? background : (disabledBackground ?? background.opacity(0.6)),
                in: Capsule()
            )
            .contentShape(Capsule())
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

/// Plain text button in a given colour (Material `TextButton`).
struct TextLinkButton: View {
    let title: String
    var color: Color = Palette.coffeePrimary
    var font: Font = .system(size: 14, weight: .medium)
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(font)
                .foregroundStyle(color)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
