//
//  DeliveryComposer.swift
//  DeliveryFeature
//
//  Created by Любченко Станислав Валерьевич on 22.12.2025.
//

import UIKit

public struct DeliveryDependencies {
    let pickupPointsManager: PickupPointsManaging

    public init(pickupPointsManager: PickupPointsManaging) {
        self.pickupPointsManager = pickupPointsManager
    }
}

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

    func makeFavoritePickupPointDeleteConfirmationViewController(
        pickupPoint: PickupPoint,
        onConfirm: @escaping () -> Void
    ) -> UIViewController
}

struct DeliveryComposer: DeliveryComposing {
    init(dependencies: DeliveryDependencies) {
        self.dependencies = dependencies
    }

    func makePickupPointsViewController(
        with eventHandler: @escaping PickupPointsEventHandler
    ) -> UIViewController {
        let interactor = PickupPointsInteractor(manager: dependencies.pickupPointsManager)
        let presenter = PickupPointsPresenter(interactor: interactor, onEvent: eventHandler)
        let viewController = PickupPointsViewController(viewOutput: presenter)
        presenter.view = viewController
//        viewController.hidesBottomBarWhenPushed = true
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
        let interactor = AddPickupPointsInteractor(manager: dependencies.pickupPointsManager)
        let presenter = AddPickupPointsPresenter(interactor: interactor, onEvent: eventHandler)
        let viewController = AddPickupPointsViewController(viewOutput: presenter)
        presenter.view = viewController
        return viewController
    }

    func makeFavoritePickupPointDeleteConfirmationViewController(
        pickupPoint: PickupPoint,
        onConfirm: @escaping () -> Void
    ) -> UIViewController {
        let alert = UIAlertController(
            title: "Удалить ПВЗ?",
            message: "ПВЗ «\(pickupPoint.name)» будет удален из списка избранных и перемещен в список доступных ПВЗ.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Удалить", style: .destructive) { _ in
            onConfirm()
        })

        return alert
    }

    // MARK: - Private members

    private let dependencies: DeliveryDependencies
}
