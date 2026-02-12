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
import Core

final class MainTabsCoordinator: BaseCoordinator<TabRouter> {

    init(composer: MainTabsComposing) {
        self.composer = composer
        super.init()
    }

    override func start() {
        guard let router else { return }

        let homeViewController = composer.makeHomeViewController { [unowned self] event in
            self.handle(homeEvent: event)
        }
        let cartViewController = composer.makeCartViewController { [unowned self] event in
            self.handle(cartEvent: event)
        }

        self.homeViewController = homeViewController
        self.cartViewController = cartViewController

        router.setTabs([homeViewController, cartViewController], animated: false)
    }

    // MARK: - Private members

    private var homeViewController: (UIViewController & HomeInput)?
    private var cartViewController: (UIViewController & CartInput)?
    private let composer: MainTabsComposing

    private func handle(homeEvent: HomeEvent) {
        switch homeEvent {
        case .placeOrder(let orderID):
            guard let cartViewController else { return }
            router?.selectModule(cartViewController)
            cartViewController.placeOrder(orderID)
        case .selectPickupPoint:
            let pickupPointsViewController = DeliveryFeature.pickupPointsViewController(embeddedInNavigationStack: true)
            homeViewController?.presentPickupPointsViewController(pickupPointsViewController)
        }
    }

    private func handle(cartEvent: CartEvent) {
        switch cartEvent {
        case .changePickupPoint:
            router?.present(DeliveryFeature.pickupPointsViewController(), animated: true, completion: nil)
        }
    }
}
