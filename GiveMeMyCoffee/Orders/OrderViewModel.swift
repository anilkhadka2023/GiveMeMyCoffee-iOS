import Foundation

@MainActor
@Observable
final class OrderViewModel {
    private let menuRepository = MenuRepository()
    private let cart: CartRepository
    private let profile: ProfileRepository

    private(set) var cafe: Cafe?
    private(set) var menu: [MenuItem] = []
    private(set) var isFavourite = false

    init() {
        cart = .shared
        profile = .shared
    }

    var cartLines: [CartLine] { cart.lines }

    var itemCount: Int { cartLines.reduce(0) { $0 + $1.quantity } }

    var total: Double { cartLines.reduce(0) { $0 + $1.lineTotal } }

    func load() async {
        guard cafe == nil else { return }
        cafe = await menuRepository.cafe()
        menu = await menuRepository.menu()
    }

    func addItem(id: String) {
        guard let item = menu.first(where: { $0.id == id }), !item.soldOut else { return }
        cart.add(item, milk: profile.profile.usualMilk)
    }

    func toggleFavourite() {
        isFavourite.toggle()
    }
}
