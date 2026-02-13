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

    override func start() {
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
    func placeOrder(_ orderID: Int) {
        router?.popToRoot(animated: false, completion: nil)

        let placeOrderVC = composer.makePlaceOrderViewController(with: orderID) { [unowned self] event in
            switch event {
            case .onBackTap:
                self.router?.pop(animated: true, completion: nil)
            case .onChangePickupPointTap:
                self.eventHandler(.changePickupPoint(self))
            case .onCompletion:
                let orderConfirmationVC = self.composer.makeOrderConfirmationViewController { event in
                    switch event {
                    case .onReturnTap:
                        self.router?.popToRoot(animated: true , completion: nil)
                    }
                }
                self.router?.push(orderConfirmationVC, animated: true, completion: nil)
            }
        }
        router?.push(placeOrderVC, animated: true, completion: nil)
    }
}

extension CartCoordinatingLogic: CartCoordinating {
    func presentPickupPoints(module: UIViewController) {
        router?.present(module, animated: true, completion: nil)
    }
}
