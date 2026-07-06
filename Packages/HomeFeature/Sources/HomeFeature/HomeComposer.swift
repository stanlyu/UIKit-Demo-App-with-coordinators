import UIKit
import Core

typealias HomePresenterEventHandler = (HomePresenter.Event) -> Void

enum HomeRoute {
    case home(eventHandler: HomePresenterEventHandler)
}

@MainActor
protocol HomeComposing: Composing where Route == HomeRoute {}

struct HomeComposer: HomeComposing {
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

        }
    }
}
