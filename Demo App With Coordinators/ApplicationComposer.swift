//
//  ApplicationComposer.swift
//  Demo App With Coordinators
//
//  Created by Любченко Станислав Валерьевич on 17.12.2025.
//

import UIKit

protocol ApplicationComposing {
    func makeLaunchViewController(with eventHandler: @escaping (LaunchScreenEvent) -> Void) -> UIViewController
    func makeMainTabsViewController() -> UIViewController
}

struct ApplicationComposer: ApplicationComposing {
    func makeLaunchViewController(with eventHandler: @escaping (LaunchScreenEvent) -> Void) -> UIViewController {
        let viewController = LaunchViewController()
        let presenter = LaunchPresenter(
            interactor: LaunchInteractor(service: LaunchService()),
            onEvent: eventHandler
        )
        viewController.output = presenter
        presenter.view = viewController
        return viewController
    }

    func makeMainTabsViewController() -> UIViewController {
        let mainTabsComposer = MainTabsComposer()
        return MainTabsCoordinator(composer: mainTabsComposer)
    }
}
