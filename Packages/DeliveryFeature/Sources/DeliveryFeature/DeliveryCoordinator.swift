//
//  DeliveryCoordinator.swift
//  DeliveryFeature
//
//  Created by Любченко Станислав Валерьевич on 22.12.2025.
//

import UIKit

final class DeliveryCoordinator: UIViewController {
    init(composer: DeliveryComposing) {
        self.composer = composer
        super.init(nibName: nil, bundle: nil)
        pickupPointsNavigationController = composer.makePickupPointsViewController { [unowned self] event in
            switch event {
            case .onAddPickupPoint:
                let addPickupPointViewController = self.composer.makeAddPickupPointViewController {
                    [unowned self] event in
                    switch event {
                    case .onBackTap:
                        self.pickupPointsNavigationController.popViewController(animated: true)
                    }
                }
                self.pickupPointsNavigationController.pushViewController(addPickupPointViewController, animated: true)
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupChildViewController(pickupPointsNavigationController)
    }

    // MARK: - Private members

    private let composer: DeliveryComposing
    private var pickupPointsNavigationController: UINavigationController!
}
