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
        self.eventHandler = eventHandler
        super.init(nibName: nil, bundle: nil)
        let rootViewController = composer.makeCartViewController { [unowned self] event in
            switch event {
            case .onPlaceOrderTap(let orderID):
                self.placeOrder(orderID)
            }
        }
        self.setViewControllers([rootViewController], animated: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private members

    private let composer: CartComposing
    private let eventHandler: (CartEvent) -> Void
}

extension CartCoordinator: CartInput {
    func placeOrder(_ orderID: Int) {
        if viewControllers.count > 1 {
            popToRootViewController(animated: false)
        }

        let placeOrderVC = composer.makePlaceOrderViewController(with: orderID) { [unowned self] event in
            switch event {
            case .onBackTap:
                self.popViewController(animated: true)
            case .onChangePickupPointTap:
                self.eventHandler(.changePickupPoint)
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
