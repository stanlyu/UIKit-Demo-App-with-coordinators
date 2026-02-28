import UIKit
import Core

typealias PickupPointsEventHandler = (PickupPointsPresenter.Event) -> Void
typealias AddPickupPointEventHandler = (AddPickupPointsPresenter.Event) -> Void

enum DeliveryRoute {
    case pickupPoints(eventHandler: PickupPointsEventHandler)
    case addPickupPoint(eventHandler: AddPickupPointEventHandler)
    case deleteConfirmation(pickupPoint: PickupPoint, onConfirm: () -> Void)
}

@MainActor
protocol DeliveryComposing: Composing where Route == DeliveryRoute {}

struct DeliveryComposer: DeliveryComposing {
    init(dependencies: DeliveryDependencies, showsBackButtonOnRoot: Bool) {
        self.dependencies = dependencies
        self.showsBackButtonOnRoot = showsBackButtonOnRoot
    }

    func makeViewController(for route: DeliveryRoute, capability: ComposeCapability) -> UIViewController {
        switch route {
        case .pickupPoints(let eventHandler):
            let interactor = PickupPointsInteractor(manager: dependencies.pickupPointsManager)
            let presenter = PickupPointsPresenter(interactor: interactor, onEvent: eventHandler)
            let viewController = PickupPointsViewController(
                viewOutput: presenter,
                showsBackButtonOnRoot: showsBackButtonOnRoot
            )
            presenter.view = viewController
            return viewController

        case .addPickupPoint(let eventHandler):
            let interactor = AddPickupPointsInteractor(manager: dependencies.pickupPointsManager)
            let presenter = AddPickupPointsPresenter(interactor: interactor, onEvent: eventHandler)
            let viewController = AddPickupPointsViewController(viewOutput: presenter)
            presenter.view = viewController
            return viewController

        case let .deleteConfirmation(pickupPoint, onConfirm):
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
    }

    private let dependencies: DeliveryDependencies
    private let showsBackButtonOnRoot: Bool
}
