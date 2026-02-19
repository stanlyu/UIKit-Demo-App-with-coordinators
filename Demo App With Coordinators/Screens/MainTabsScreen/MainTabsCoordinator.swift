//
//  MainTabsCoordinator.swift
//  Demo App With Coordinators
//
//  Created by Любченко Станислав Валерьевич on 18.12.2025.
//

import UIKit
import HomeFeature
import CartFeature
import DeliveryFeature
import PaymentFeature
import Core

typealias MainTabsCoordinator = MainTabsCoordinatingLogic<TabRouter>

final class MainTabsCoordinatingLogic<Router: TabRouting>: Coordinator<Router> {

    init(composer: MainTabsComposing) {
        self.composer = composer
        super.init()
    }

    override func start() {
        guard let router else { return }

        let homeViewController = composer.makeHomeViewController { [unowned self] event in
            self.handle(homeEvent: event)
        }
        let cartModule = composer.makeCartViewController { [unowned self] event in
            self.handle(cartEvent: event)
        }

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
        case .selectPickupPoint(let homeCoordinator):
            let pickupPointsViewController = composer.makePickupPointsViewController(
                embeddedInNavigationStack: true
            )
            homeCoordinator.presentPickupPoints(module: pickupPointsViewController)
        }
    }

    private func handle(cartEvent: CartEvent) {
        switch cartEvent {
        case .changePickupPoint(let cartCoordinator):
            let pickupPointsViewController = composer.makePickupPointsViewController(
                embeddedInNavigationStack: false
            )
            cartCoordinator.presentPickupPoints(viewController: pickupPointsViewController)
        case .continueToPayment(let cartCoordinator):
            let paymentViewController = composer.makePaymentViewController { [weak self, weak cartCoordinator] event in
                guard let self, let cartCoordinator else { return }

                switch event {
                case .cancelled:
                    cartCoordinator.closePayment()
                case let .completed(paymentResult):
                    let cartPaymentResult = self.composer.makeCartPaymentResult(from: paymentResult)
                    cartCoordinator.completePayment(with: cartPaymentResult)
                }
            }
            cartCoordinator.showPayment(viewController: paymentViewController)
        }
    }
}
