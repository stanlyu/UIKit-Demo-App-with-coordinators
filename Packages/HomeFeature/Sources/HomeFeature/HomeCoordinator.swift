//
//  HomeCoordinator.swift
//  HomeFeature
//
//  Created by Любченко Станислав Валерьевич on 19.12.2025.
//

import UIKit
import Core

typealias HomeCoordinator = HomeCoordinatingLogic<StackRouter>

final class HomeCoordinatingLogic<Router: StackRouting>: Coordinator<StackRouter> {
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
                eventHandler(.selectPickupPoint(self))
            }
        }
        router?.push(rootViewController, animated: false, completion: nil)
    }

    // MARK: - Private members

    private let composer: HomeComposing
    private let eventHandler: (HomeEvent) -> Void
}

extension HomeCoordinatingLogic: HomeInput {
    func presentPickupPoints(module: UIViewController) {
        router?.push(module, animated: true, completion: nil)
    }
}
