//
//  DeliveryCoordinator.swift
//  DeliveryFeature
//
//  Created by Любченко Станислав Валерьевич on 22.12.2025.
//

import UIKit
import Core

final class DeliveryCoordinator: ParentViewController {

    init(composer: DeliveryComposing) {
        self.composer = composer
        super.init(nibName: nil, bundle: nil)
        var eventHandler = EventHandler(composer: composer)
        pickupPointsViewController = composer.makePickupPointsViewController { [unowned self] event in
            eventHandler.navigationController = self.navigationController
            eventHandler.handle(event: event)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        putChildViewController(pickupPointsViewController)
    }

    // MARK: - Private members

    private let composer: DeliveryComposing
    private var pickupPointsViewController: UIViewController!
}

final class DeliveryNavigationCoordinator: UINavigationController {
    init(composer: DeliveryComposing) {
        self.composer = composer
        super.init(nibName: nil, bundle: nil)
        var eventHandler = EventHandler(composer: composer)
        pickupPointsViewController = composer.makePickupPointsViewController { [unowned self] event in
            eventHandler.navigationController = self
            eventHandler.handle(event: event)
        }
        setViewControllers([pickupPointsViewController], animated: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private members

    private let composer: DeliveryComposing
    private var pickupPointsViewController: UIViewController!
}

@MainActor
private struct EventHandler {
    let composer: DeliveryComposing
    var navigationController: UINavigationController?

    func handle(event: PickupPointsPresenter.Event) {
        switch event {
        case .onAddPickupPoint:
            let addPickupPointViewController = composer.makeAddPickupPointViewController { event in
                switch event {
                case .onBackTap:
                    navigationController?.popViewController(animated: true)
                }
            }
            navigationController?.pushViewController(addPickupPointViewController, animated: true)
        }
    }
}
