//
//  MainTabsCoordinator.swift
//  Demo App With Coordinators
//
//  Created by Любченко Станислав Валерьевич on 18.12.2025.
//

import UIKit
import HomeFeature
import CartFeature
import Core

typealias MainTabsCoordinator = MainTabsCoordinatingLogic<TabRouter>

final class MainTabsCoordinatingLogic<Router: TabRouting>: Coordinator<Router> {

    init(composer: MainTabsComposing) {
        self.composer = composer
        super.init()
    }

    override func start(_ capability: StartCapability) {
        guard let router else { return }

        let homeViewController = composer.makeHomeViewController { [unowned self] event in
            self.handle(homeEvent: event)
        }
        let cartModule = composer.makeCartViewController()

        self.cartModule = cartModule
        router.setViewControllers([homeViewController, cartModule.viewController], animated: false)
    }

    // MARK: - Private members

    private var cartModule: CartModule?
    private let composer: MainTabsComposing

    private func handle(homeEvent: HomeEvent) {
        switch homeEvent {
        case .placeOrder(let orderID):
            guard let cartModule else { return }
            router?.selectViewController(cartModule.viewController)
            cartModule.coordinator.placeOrder(orderID)
        }
    }
}
