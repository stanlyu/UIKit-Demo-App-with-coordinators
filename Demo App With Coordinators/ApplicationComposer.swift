//
//  ApplicationComposer.swift
//  Demo App With Coordinators
//
//  Created by Любченко Станислав Валерьевич on 17.12.2025.
//

import UIKit
import Core

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
        let mainTabsCoordinator = MainTabsCoordinator(composer: mainTabsComposer)
        let mainTabsRouter = TabRouter(coordinator: mainTabsCoordinator)
        mainTabsCoordinator.router = mainTabsRouter
        configureMainTabsRouter(mainTabsRouter)
        return mainTabsRouter
    }

    private func configureMainTabsRouter(_ router: TabRouter) {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()

        let fontSize: CGFloat = 12
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize, weight: .medium),
            .foregroundColor: UIColor.secondaryLabel
        ]
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize, weight: .bold),
            .foregroundColor: UIColor.systemBlue
        ]

        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.titleTextAttributes = normalAttributes
        itemAppearance.selected.titleTextAttributes = selectedAttributes

        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance

        router.tabBar.standardAppearance = appearance
        router.tabBar.scrollEdgeAppearance = appearance
    }
}
