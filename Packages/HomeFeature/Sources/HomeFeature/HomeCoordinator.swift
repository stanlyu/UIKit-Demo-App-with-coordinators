//
//  HomeCoordinator.swift
//  HomeFeature
//
//  Created by Любченко Станислав Валерьевич on 19.12.2025.
//

import UIKit
import Core

final class HomeCoordinator: UIViewController {
    init(composer: HomeComposing, eventHandler: @escaping (HomeEvent) -> Void) {
        self.composer = composer
        super.init(nibName: nil, bundle: nil)
        homeNavigationController = composer.makeHomeNavigationController { [unowned self] event in
            switch event {
            case .onPlaceOrderTap(let orderID):
                eventHandler(.placeOrder(orderID))
            case .onPickupPointTap:
                eventHandler(.selectPickupPoint)
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupChildViewController(homeNavigationController)
    }

    // MARK: - Private members

    private let composer: HomeComposing
    private var homeNavigationController: UINavigationController!
}
