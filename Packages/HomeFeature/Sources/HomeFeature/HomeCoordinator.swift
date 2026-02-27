//
//  HomeCoordinator.swift
//  HomeFeature
//
//  Created by Любченко Станислав Валерьевич on 19.12.2025.
//

import UIKit
import Core

typealias HomeCoordinator = HomeCoordinatingLogic<StackRouter>

final class HomeCoordinatingLogic<Router: StackRouting>: Coordinator<Router> {
    init(composer: HomeComposing, eventHandler: @escaping (HomeEvent) -> Void) {
        self.composer = composer
        self.eventHandler = eventHandler
        super.init()
    }

    override func start(_ capability: StartCapability) {
        let rootViewController = composer.makeHomeViewController { [unowned self] event in
            switch event {
            case .onPlaceOrderTap(let orderID):
                eventHandler(.placeOrder(orderID))
            case .onPickupPointTap:
                showPickupPoints()
            }
        }
        router?.push(rootViewController, animated: false, completion: nil)
    }

    // MARK: - Private members

    private let composer: HomeComposing
    private let eventHandler: (HomeEvent) -> Void

    private func showPickupPoints() {
        let pickupPointsViewController = composer.makePickupPointsViewController { [weak self] in
            self?.router?.pop(animated: true, completion: nil)
        }
        router?.push(pickupPointsViewController, animated: true, completion: nil)
    }
}
