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

final class MainTabsCoordinator: UIViewController {

    init(composer: MainTabsComposing) {
        self.composer = composer
        super.init(nibName: nil, bundle: nil)
        homeViewController = composer.makeHomeViewController { [unowned self] event in
            self.handle(homeEvent: event)
        }
        cartViewController = composer.makeCartViewController { [unowned self] event in
            self.handle(cartEvent: event)
        }
        _tabBarController = composer.makeTabBarController(with: [homeViewController, cartViewController])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupChildViewController(_tabBarController)
    }

    // MARK: - Private members

    private var _tabBarController: UITabBarController!
    private var homeViewController: (UIViewController & HomeInput)!
    private var cartViewController: (UIViewController & CartInput)!
    private let composer: MainTabsComposing

    private func handle(homeEvent: HomeEvent) {
        switch homeEvent {
        case .placeOrder(let orderID):
            _tabBarController.selectedViewController = cartViewController
            cartViewController.placeOrder(orderID)
        case .selectPickupPoint:
            let pickupPointsViewController = DeliveryFeature.pickupPointsViewController(embeddedInNavigationStack: true)
            homeViewController.presentPickupPointsViewController(pickupPointsViewController)
        }
    }

    private func handle(cartEvent: CartEvent) {
        switch cartEvent {
        case .changePickupPoint:
            _tabBarController.present(DeliveryFeature.pickupPointsViewController(), animated: true)
        }
    }
}
