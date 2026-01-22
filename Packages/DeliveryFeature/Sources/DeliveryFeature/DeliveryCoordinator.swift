//
//  DeliveryCoordinator.swift
//  DeliveryFeature
//
//  Created by Любченко Станислав Валерьевич on 22.12.2025.
//

import UIKit

final class DeliveryCoordinator: UIViewController {
    override var navigationItem: UINavigationItem {
        if let pickupPointsViewController {
            return pickupPointsViewController.navigationItem
        } else {
            return super.navigationItem
        }
    }

    init(composer: DeliveryComposing, embeddedInNavigationStack: Bool) {
        self.composer = composer
        embedded = embeddedInNavigationStack
        super.init(nibName: nil, bundle: nil)
        if embeddedInNavigationStack {
            pickupPointsViewController = composer.makePickupPointsViewController { [unowned self] event in
                self.handle(event: event)
            }
        } else {
            pickupPointsNavigationController = composer.makePickupPointsNavigationController { [unowned self] event in
                self.handle(event: event)
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let childViewController = embedded ? pickupPointsViewController : pickupPointsNavigationController
        else { return }
        setupChildViewController(childViewController)
    }

    // MARK: - Private members

    private let composer: DeliveryComposing
    private var pickupPointsNavigationController: UINavigationController?
    private var pickupPointsViewController: UIViewController?
    private let embedded: Bool
    private var actualNavigationController: UINavigationController? {
        embedded ? navigationController : pickupPointsNavigationController
    }

    private func handle(event: PickupPointsPresenter.Event) {
        switch event {
        case .onAddPickupPoint:
            let addPickupPointViewController = composer.makeAddPickupPointViewController {
                [unowned self] event in
                switch event {
                case .onBackTap:
                    self.actualNavigationController?.popViewController(animated: true)
                }
            }
            actualNavigationController?.pushViewController(addPickupPointViewController, animated: true)
        }
    }
}
