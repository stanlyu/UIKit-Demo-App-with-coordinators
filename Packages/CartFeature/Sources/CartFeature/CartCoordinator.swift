//
//  CartCoordinator.swift
//  Demo App With Coordinators
//
//  Created by Любченко Станислав Валерьевич on 18.12.2025.
//

import UIKit
import Core

final class CartCoordinator: UIViewController {
    init(composer: CartComposing, eventHandler: @escaping (CartEvent) -> Void) {
        self.composer = composer
        super.init(nibName: nil, bundle: nil)
        cartNavigationController = composer.makeCartViewController { [unowned self] event in
            switch event {
            case .onPlaceOrderTap(let orderID):
                self.placeOrder(orderID, eventHandler: eventHandler)
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupChildViewController(cartNavigationController)
    }

    // MARK: - Private members

    private let composer: CartComposing
    private var cartNavigationController: UINavigationController!
}

extension CartCoordinator: CartInput {
    func placeOrder(_ orderID: Int, eventHandler: @escaping (CartEvent) -> Void) {
        let placeOrderVC = composer.makePlaceOrderViewController(with: orderID) { [unowned self] event in
            switch event {
            case .onBackTap:
                self.cartNavigationController.popViewController(animated: true)
            case .onChangePickupPointTap:
                eventHandler(.changePickupPoint)
            case .onCompletion:
                let orderConfirmationVC = self.composer.makeOrderConfirmationViewController()
                self.cartNavigationController.pushViewController(orderConfirmationVC, animated: true)
            }
        }
        cartNavigationController.pushViewController(placeOrderVC, animated: true)
    }
}
