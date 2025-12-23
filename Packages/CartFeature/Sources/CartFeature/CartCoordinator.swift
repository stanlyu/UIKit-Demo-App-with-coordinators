//
//  CartCoordinator.swift
//  Demo App With Coordinators
//
//  Created by Любченко Станислав Валерьевич on 18.12.2025.
//

import UIKit
import Core

final class CartCoordinator: UINavigationController {
    init(composer: CartComposing, eventHandler: @escaping (CartEvent) -> Void) {
        self.composer = composer
        super.init(nibName: nil, bundle: nil)
        let rootViewController = composer.makeCartViewController { [unowned self] event in
            switch event {
            case .onPlaceOrderTap(let orderID):
                self.placeOrder(orderID, eventHandler: eventHandler)
            }
        }
        self.setViewControllers([rootViewController], animated: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private members

    private let composer: CartComposing
}

extension CartCoordinator: CartInput {
    func placeOrder(_ orderID: Int, eventHandler: @escaping (CartEvent) -> Void) {
        let placeOrderVC = composer.makePlaceOrderViewController(with: orderID) { [unowned self] event in
            switch event {
            case .onBackTap:
                self.popViewController(animated: true)
            case .onChangePickupPointTap:
                eventHandler(.changePickupPoint)
            case .onCompletion:
                let orderConfirmationVC = self.composer.makeOrderConfirmationViewController { event in
                    switch event {
                    case .onReturnTap:
                        self.popToRootViewController(animated: true)
                    }
                }
                self.pushViewController(orderConfirmationVC, animated: true)
            }
        }
        pushViewController(placeOrderVC, animated: true)
    }
}
