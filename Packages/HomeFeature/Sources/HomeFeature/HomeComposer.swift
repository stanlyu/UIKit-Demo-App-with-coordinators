import UIKit
import Core

typealias HomeEventHandler = (HomePresenter.Event) -> Void

enum HomeRoute {
    case home(eventHandler: HomeEventHandler)
    case pickupPoints(onClose: () -> Void)
}

@MainActor
protocol HomeComposing: Composing where Route == HomeRoute {}

struct HomeComposer: HomeComposing {
    init(dependencies: HomeDependencies) {
        self.dependencies = dependencies
    }

    func makeViewController(for route: HomeRoute, capability: ComposeCapability) -> UIViewController {
        switch route {
        case .home(let eventHandler):
            let service = HomeService()
            let interactor = HomeInteractor(service: service)
            let homePresenter = HomePresenter(interactor: interactor, onEvent: eventHandler)
            let homeViewController = HomeViewController()
            homePresenter.view = homeViewController
            homeViewController.viewOutput = homePresenter
            return homeViewController

        case .pickupPoints(let onClose):
            guard let externalModulesFactory = dependencies.externalModulesFactory else {
                assertionFailure("External modules factory is missing")
                return UIViewController()
            }
            return externalModulesFactory.makePickupPointsViewController(onClose: onClose)
        }
    }

    private let dependencies: HomeDependencies
}
