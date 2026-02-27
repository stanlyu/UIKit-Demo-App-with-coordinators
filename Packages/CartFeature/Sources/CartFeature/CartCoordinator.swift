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
    init(composer: CartComposing) {
        self.composer = composer
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
    
    private func showPickupPoints() {
        let pickupPointsVC = composer.makePickupPointsViewController()
        router?.present(pickupPointsVC, animated: true, completion: nil)
    }

    private func showPayment() {
        let paymentVC = composer.makePaymentViewController { [weak self] result in
            guard let self else { return }

            if let result {
                completePayment(with: result)
            } else {
                router?.pop(animated: true, completion: nil)
            }
        }
        router?.push(paymentVC, animated: true, completion: nil)
    }

    private func completePayment(with result: CartPaymentResult) {
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

extension CartCoordinatingLogic: CartInput {
    func placeOrder(_ orderID: Int) {
        router?.popToRoot(animated: false, completion: nil)

        let placeOrderVC = composer.makePlaceOrderViewController(with: orderID) { [unowned self] event in
            switch event {
            case .onBackTap:
                self.router?.pop(animated: true, completion: nil)
            case .onChangePickupPointTap:
                self.showPickupPoints()
            case .onContinueToPayment:
                self.showPayment()
            }
        }
        router?.push(placeOrderVC, animated: true, completion: nil)
    }
}
