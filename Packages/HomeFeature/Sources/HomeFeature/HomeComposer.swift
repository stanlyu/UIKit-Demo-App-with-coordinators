import UIKit
import Core

typealias HomePresenterEventHandler = (HomePresenter.Event) -> Void

enum HomeRoute {
    case home(eventHandler: HomePresenterEventHandler)
    case pickupPoints(onClose: () -> Void)
}

@MainActor
protocol HomeComposing: Composing where Route == HomeRoute {}

struct HomeComposer: HomeComposing {
    private let dependencies: HomeBusinessDependencies

    init(dependencies: HomeBusinessDependencies) {
        self.dependencies = dependencies
    }

    func makeViewController(for route: HomeRoute) -> UIViewController {
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
            return dependencies.externalScreensProvider.makePickupPointsViewController(onClose: onClose)
        }
    }
}
