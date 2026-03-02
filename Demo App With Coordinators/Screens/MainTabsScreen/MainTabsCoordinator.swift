import UIKit
import HomeFeature
import CartFeature
import Core

typealias MainTabsCoordinator = MainTabsCoordinatingLogic<TabRouter>

final class MainTabsCoordinatingLogic<Router: TabRouting>: Coordinator<Router, MainTabsRoute> {

    override func start(_ capability: StartCapability) {
        guard let router else { return }

        let homeItem = composer.makeItem(
            for: .home(
                eventHandler: { [weak self] event in
                    self?.handle(homeEvent: event)
                }
            )
        )

        let cartItem = composer.makeItem(
            for: .cart(
                onCreated: { [weak self] input in
                    self?.cartInput = input
                }
            )
        )

        self.cartItem = cartItem
        router.setItems([homeItem, cartItem], animated: false)
    }

    private var cartItem: RouterItem?
    private var cartInput: CartInput?

    private func handle(homeEvent: HomeEvent) {
        switch homeEvent {
        case .placeOrder(let orderID):
            guard let cartItem else { return }
            router?.selectItem(cartItem)
            cartInput?.placeOrder(orderID)
        }
    }
}
