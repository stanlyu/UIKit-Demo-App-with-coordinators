//
//  CartCoordinator.swift
//  Demo App With Coordinators
//
//  Created by Любченко Станислав Валерьевич on 18.12.2025.
//

import UIKit
import Core

typealias CartCoordinator = CartCoordinatingLogic<StackRouter>

final class CartCoordinatingLogic<Router: StackRouting>: Coordinator<Router> {
    init(composer: CartComposing, eventHandler: @escaping (CartEvent) -> Void) {
        self.composer = composer
        self.eventHandler = eventHandler
        super.init()
    }

    override func start(_ capability: StartCapability) {
        let rootViewController = composer.makeCartViewController { [unowned self] event in
            switch event {
            case .onPlaceOrderTap(let orderID):
                self.placeOrder(orderID)
            }
        }
        router?.push(rootViewController, animated: false, completion: nil)
    }

    // MARK: - Private members

    private let composer: CartComposing
    private let eventHandler: (CartEvent) -> Void
}

extension CartCoordinatingLogic: CartInput {
    func presentPickupPoints(viewController: UIViewController) {
        router?.present(viewController, animated: true, completion: nil)
    }

    func showPayment(viewController: UIViewController) {
        router?.push(viewController, animated: true, completion: nil)
    }

    func closePayment() {
        router?.pop(animated: true, completion: nil)
    }

    func placeOrder(_ orderID: Int) {
        router?.popToRoot(animated: false, completion: nil)

        let placeOrderVC = composer.makePlaceOrderViewController(with: orderID) { [unowned self] event in
            switch event {
            case .onBackTap:
                self.router?.pop(animated: true, completion: nil)
            case .onChangePickupPointTap:
                self.eventHandler(.changePickupPoint(self))
            case .onContinueToPayment:
                self.eventHandler(.continueToPayment(self))
            }
        }
        router?.push(placeOrderVC, animated: true, completion: nil)
    }

    func completePayment(with result: CartPaymentResult) {
        guard let router, let cartRootViewController = router.viewControllers.first else { return }

        let orderConfirmationVC = composer.makeOrderConfirmationViewController(
            paymentResult: result
        ) { [weak self] event in
            switch event {
            case .onReturnTap:
                self?.router?.popToRoot(animated: true, completion: nil)
            }
        }

        router.push(orderConfirmationVC, animated: true) { [weak self] in
            self?.router?.setStack([cartRootViewController, orderConfirmationVC], animated: false)
        }
    }
}
