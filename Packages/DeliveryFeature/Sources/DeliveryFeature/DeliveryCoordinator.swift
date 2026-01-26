//
//  DeliveryCoordinator.swift
//  DeliveryFeature
//
//  Created by Любченко Станислав Валерьевич on 22.12.2025.
//

import UIKit
import Core

final class DeliveryCoordinator: UIViewController {

    init(composer: DeliveryComposing) {
        self.composer = composer
        super.init(nibName: nil, bundle: nil)
        pickupPointsViewController = composer.makePickupPointsViewController { [unowned self] event in
            handle(event: event)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        pickupPointsViewController.setup(navigationItem: navigationItem)
        setupChildViewController(pickupPointsViewController)
    }

    // MARK: - Private members

    private let composer: DeliveryComposing
    private var pickupPointsViewController: PickupPointsViewController!

    private func handle(event: PickupPointsPresenter.Event) {
        switch event {
        case .onAddPickupPoint:
            let addPickupPointViewController = composer.makeAddPickupPointViewController { [unowned self] event in
                switch event {
                case .onBackTap:
                    navigationController?.popViewController(animated: true)
                }
            }
            navigationController?.pushViewController(addPickupPointViewController, animated: true)
        }
    }
}
