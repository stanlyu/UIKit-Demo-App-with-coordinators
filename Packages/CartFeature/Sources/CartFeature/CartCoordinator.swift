import UIKit
import Core

typealias CartCoordinator = CartCoordinatingLogic

final class CartCoordinatingLogic: BaseCoordinator<any StackNavigation, CartRoute> {
    init<C: CartComposing>(
        router: any StackNavigation,
        composer: C,
        onEvent: @escaping (CartNavigationOutputEvent) -> Void
    ) {
        self.onEvent = onEvent
        super.init(router: router, composer: composer)
    }

    override func start(_ context: CoordinatorStartContext) {
        let item = composer.makeItem(for: .cart(eventHandler: { [weak self] event in
            switch event {
            case .onPlaceOrderTap(let orderID):
                self?.placeOrder(orderID)
            }
        }))
        router.setRoot(item, animated: false)
    }

    private let onEvent: (CartNavigationOutputEvent) -> Void
    private var pickupPointsItem: RouterItem?
    private var paymentItem: RouterItem?

    private func requestPickupPoints() {
        let item = composer.makeItem(for: .pickupPoints(onClose: { [weak self] in
            self?.router.dismiss(animated: true, completion: nil)
        }))
        self.pickupPointsItem = item
        router.present(item, animated: true, completion: nil)
    }

    private func requestPayment() {
        let item = composer.makeItem(for: .payment(onComplete: { [weak self] result in
            guard let self else { return }
            if let result = result {
                self.completePayment(with: result)
            } else {
                self.router.pop(animated: true, completion: nil)
            }
        }))
        self.paymentItem = item
        router.push(item, animated: true, completion: nil)
    }

    private func completePayment(with result: CartPaymentResult) {
        guard let cartRootItem = router.items.first else { return }

        let item = composer.makeItem(for: .orderConfirmation(paymentResult: result, eventHandler: { [weak self] event in
            switch event {
            case .onReturnTap:
                self?.router.popToRoot(animated: true, completion: nil)
            }
        }))

        router.push(item, animated: true) { [weak self] in
            self?.router.setStack([cartRootItem, item], animated: false)
        }
    }
}

extension CartCoordinatingLogic: CartNavigationInput {
    func placeOrder(_ orderID: Int) {
        router.popToRoot(animated: false, completion: nil)

        let item = composer.makeItem(for: .placeOrder(orderID: orderID, eventHandler: { [weak self] event in
            switch event {
            case .onBackTap:
                self?.router.pop(animated: true, completion: nil)
            case .onChangePickupPointTap:
                self?.requestPickupPoints()
            case .onContinueToPayment:
                self?.requestPayment()
            }
        }))
        router.push(item, animated: true, completion: nil)
    }
}
