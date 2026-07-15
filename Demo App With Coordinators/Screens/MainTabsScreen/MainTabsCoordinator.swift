import UIKit
import HomeFeature
import CartFeature
import DeliveryFeature
import Core

typealias MainTabsCoordinator = MainTabsCoordinatingLogic

final class MainTabsCoordinatingLogic: BaseCoordinator<any TabsNavigation, MainTabsRoute> {

    init<C: MainTabsComposing>(
        router: any TabsNavigation,
        composer: C
    ) {
        super.init(router: router, composer: composer)
    }

    override func start(_ context: CoordinatorStartContext) {
        let homeItem = composer.makeItem(
            for: .home(
                onEvent: { [weak self] event in
                    self?.handle(homeEvent: event)
                }
            )
        )

        let cartItem = composer.makeItem(
            for: .cart(
                onCreated: { [weak self] input in
                    self?.cartNavigationInput = input
                },
                onEvent: { [weak self] event in
                    self?.handle(cartEvent: event)
                }
            )
        )

        self.cartItem = cartItem
        router.setItems([homeItem, cartItem], animated: false)
    }

    private var cartItem: RouterItem?
    private weak var cartNavigationInput: (any CartNavigationInput)?

    private func handle(homeEvent: HomeNavigationOutputEvent) {
        print("[MainTabsCoordinator] handle homeEvent: \(homeEvent)")
        switch homeEvent {
        case .placeOrder(let orderID):
            guard let cartItem else { return }
            router.selectItem(cartItem)
            cartNavigationInput?.placeOrder(orderID)

        case let .pickupPointsRequested(context, onClose):
            let item = composer.makeItem(for: .pickupPoints(
                embeddedInNavigationStack: true,
                onEvent: { event in
                    switch event {
                    case .didClose:
                        onClose()
                    }
                }
            ))
            print("[MainTabsCoordinator] pushing pickupPoints in context: \(context)")
            context.push(item, animated: true)
        }
    }

    private func handle(cartEvent: CartNavigationOutputEvent) {
        switch cartEvent {
        case let .pickupPointsRequested(context, onClose):
            let item = composer.makeItem(for: .pickupPoints(
                embeddedInNavigationStack: false,
                onEvent: { event in
                    switch event {
                    case .didClose:
                        onClose()
                    }
                }
            ))
            context.present(item, animated: true)

        case let .paymentRequested(context, onComplete):
            let item = composer.makeItem(for: .payment(onComplete: onComplete))
            context.push(item, animated: true)
        }
    }
}
