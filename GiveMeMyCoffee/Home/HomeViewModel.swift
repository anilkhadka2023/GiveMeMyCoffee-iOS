import Foundation

@MainActor
@Observable
final class HomeViewModel {
    let cafes = CafesViewModel(refetchOnApply: false)
    var showLogoutConfirm = false

    func greetingName(session: AppSession) -> String {
        let candidates = [session.userName ?? "", ProfileRepository.shared.profile.firstName]
        return candidates.first { !$0.isBlank } ?? "Anil"
    }

    func logOut(session: AppSession) async {
        let result = await AuthRepository.shared.logout()
        if case .error(let message, _) = result {
            ToastCenter.shared.show("Logged out locally. Server sign-out failed: \(message)", long: true)
        } else {
            ToastCenter.shared.show("You've been logged out")
        }
        session.didSignOut()
    }

    func comingSoon(_ label: String) {
        ToastCenter.shared.show("\(label) is coming soon")
    }
}
