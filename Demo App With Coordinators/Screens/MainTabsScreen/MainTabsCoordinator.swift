//
//  TabsCoordinator.swift
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
        mainViewController = composer.makeHomeViewController { [weak self] event in
            self?.handle(event: event)
        }
        cartViewController = composer.makeCartViewController { [weak self] input in
            self?.cartInput = input
        }
        _tabBarController = composer.makeTabBarController(with: [mainViewController, cartViewController])
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
    private var mainViewController: UIViewController!
    private var cartViewController: UIViewController!
    private var cartInput: CartInput!
    private let composer: MainTabsComposing

    private func handle(event: HomeEvent) {
        switch event {
        case .placeOrder(let orderID):
            _tabBarController.selectedViewController = cartViewController
            cartInput.placeOrder(orderID)
        case .selectPickupPoint:
            _tabBarController.present(DeliveryFeature.pickupPointsViewController(), animated: true)
            break
        }
    }
}
