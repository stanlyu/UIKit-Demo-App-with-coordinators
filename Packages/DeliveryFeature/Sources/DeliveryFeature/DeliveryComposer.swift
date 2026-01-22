//
//  DeliveryComposer.swift
//  DeliveryFeature
//
//  Created by Любченко Станислав Валерьевич on 22.12.2025.
//

import UIKit

typealias PickupPointsEventHandler = (PickupPointsPresenter.Event) -> Void
typealias AddPickupPointEventHandler = (AddPickupPointsPresenter.Event) -> Void

@MainActor
protocol DeliveryComposing {
    func makePickupPointsViewController(
        with eventHandler: @escaping PickupPointsEventHandler
    ) -> UIViewController

    func makePickupPointsNavigationController(
        with eventHandler: @escaping PickupPointsEventHandler
    ) -> UINavigationController

    func makeAddPickupPointViewController(with eventHandler: @escaping AddPickupPointEventHandler) -> UIViewController
}

struct DeliveryComposer: DeliveryComposing {
    func makePickupPointsViewController(
        with eventHandler: @escaping PickupPointsEventHandler
    ) -> UIViewController {
        let service = PickupPointsService()
        let interactor = PickupPointsInteractor(service: service)
        let presenter = PickupPointsPresenter(interactor: interactor, onEvent: eventHandler)
        let viewController = PickupPointsViewController()
        presenter.view = viewController
        viewController.viewOutput = presenter
        return viewController
    }

    func makePickupPointsNavigationController(
        with eventHandler: @escaping PickupPointsEventHandler
    ) -> UINavigationController {
        let viewController = makePickupPointsViewController(with: eventHandler)
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.navigationBar.prefersLargeTitles = true
        return navigationController
    }

    func makeAddPickupPointViewController(with eventHandler: @escaping AddPickupPointEventHandler) -> UIViewController {
        let presenter = AddPickupPointsPresenter(onEvent: eventHandler)
        return AddPickupPointsViewController(viewOutput: presenter)
    }
}
