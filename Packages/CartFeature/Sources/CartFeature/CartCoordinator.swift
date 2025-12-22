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
                self.placeOrder(orderID)
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
    func placeOrder(_ orderID: Int) {
        let placeOrderVC = composer.makePlaceOrderViewController(orderID: orderID)
        cartNavigationController.pushViewController(placeOrderVC, animated: true)
    }
}
