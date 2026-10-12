import SwiftUI

/// iOS stand-in for Android's `Toast`: a short message shown above the tab bar.
@MainActor
@Observable
final class ToastCenter {
    static let shared = ToastCenter()

    private(set) var message: String?
    @ObservationIgnored private var dismissTask: Task<Void, Never>?

    func show(_ message: String, long: Bool = false) {
        self.message = message
        dismissTask?.cancel()
        dismissTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(long ? 3.5 : 2))
            guard !Task.isCancelled else { return }
            self?.message = nil
        }
    }
}

private struct ToastOverlay: ViewModifier {
    func body(content: Content) -> some View {
        let message = ToastCenter.shared.message
        content
            .overlay(alignment: .bottom) {
                if let message {
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.8), in: Capsule())
                        .padding(.horizontal, 24)
                        .padding(.bottom, 96)
                        .transition(.opacity)
                        .allowsHitTesting(false)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: message)
    }
}

extension View {
    func toastOverlay() -> some View { modifier(ToastOverlay()) }
}
