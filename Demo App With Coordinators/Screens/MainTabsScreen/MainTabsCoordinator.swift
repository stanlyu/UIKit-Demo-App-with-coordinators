//
//  TabsCoordinator.swift
//  Demo App With Coordinators
//
//  Created by Любченко Станислав Валерьевич on 18.12.2025.
//

import UIKit

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
        addChild(_tabBarController)
        view.addSubview(_tabBarController.view)

        _tabBarController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            _tabBarController.view.topAnchor.constraint(equalTo: view.topAnchor),
            _tabBarController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            _tabBarController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            _tabBarController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        _tabBarController.didMove(toParent: self)
    }

    // MARK: - Private members

    private var _tabBarController: UITabBarController!
    private var mainViewController: UIViewController!
    private var cartViewController: UIViewController!
    private var cartInput: CartInput!
    private let composer: MainTabsComposing

    private func handle(event: HomeScreenEvent) {
        switch event {
        case .placeOrder(let orderID):
            _tabBarController.selectedViewController = cartViewController
            cartInput.placeOrder(orderID)
        }
    }
}
