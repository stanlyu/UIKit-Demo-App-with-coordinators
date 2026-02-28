import UIKit
import Core

typealias CartCoordinator = CartCoordinatingLogic<StackRouter>

final class CartCoordinatingLogic<Router: StackRouting>: Coordinator<Router, CartRoute> {
    init<C: CartComposing>(composer: C) {
        super.init(composer: composer)
    }

    override func start(_ capability: StartCapability) {
        let item = composer.makeItem(for: .cart(eventHandler: { [weak self] event in
            switch event {
            case .onPlaceOrderTap(let orderID):
                self?.placeOrder(orderID)
            }
        }))
        router?.push(item, animated: false, completion: nil)
    }

    private func showPickupPoints() {
        let item = composer.makeItem(for: .pickupPoints)
        router?.present(item, animated: true, completion: nil)
    }

    private func showPayment() {
        let item = composer.makeItem(for: .payment(onComplete: { [weak self] result in
            guard let self else { return }

            if let result {
                self.completePayment(with: result)
            } else {
                self.router?.pop(animated: true, completion: nil)
            }
        }))
        router?.push(item, animated: true, completion: nil)
    }

    private func completePayment(with result: CartPaymentResult) {
        guard let router, let cartRootItem = router.items.first else { return }

        let item = composer.makeItem(for: .orderConfirmation(paymentResult: result, eventHandler: { [weak self] event in
            switch event {
            case .onReturnTap:
                self?.router?.popToRoot(animated: true, completion: nil)
            }
        }))

        router.push(item, animated: true) { [weak self] in
            self?.router?.setStack([cartRootItem, item], animated: false)
        }
    }
}

extension CartCoordinatingLogic: CartInput {
    func placeOrder(_ orderID: Int) {
        router?.popToRoot(animated: false, completion: nil)

        let item = composer.makeItem(for: .placeOrder(orderID: orderID, eventHandler: { [weak self] event in
            switch event {
            case .onBackTap:
                self?.router?.pop(animated: true, completion: nil)
            case .onChangePickupPointTap:
                self?.showPickupPoints()
            case .onContinueToPayment:
                self?.showPayment()
            }
        }))
        router?.push(item, animated: true, completion: nil)
    }
}
