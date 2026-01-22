//
//  HomeCoordinator.swift
//  HomeFeature
//
//  Created by Любченко Станислав Валерьевич on 19.12.2025.
//

import UIKit
import Core

final class HomeCoordinator: UINavigationController {
    init(composer: HomeComposing, eventHandler: @escaping (HomeEvent) -> Void) {
        self.composer = composer
        super.init(nibName: nil, bundle: nil)
        let rootViewController = composer.makeHomeViewController { [unowned self] event in
            switch event {
            case .onPlaceOrderTap(let orderID):
                eventHandler(.placeOrder(orderID))
            case .onPickupPointTap:
                eventHandler(.selectPickupPoint)
            }
        }
        self.setViewControllers([rootViewController], animated: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private members

    private let composer: HomeComposing
}

extension HomeCoordinator: HomeInput {
    func presentPickupPointsViewController(_ viewController: UIViewController) {
        pushViewController(viewController, animated: true)
    }
}
