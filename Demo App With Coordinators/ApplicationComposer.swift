import UIKit
import Core

enum ApplicationRoute {
    case launch(eventHandler: (LaunchScreenEvent) -> Void)
    case mainFlow
}

@MainActor
protocol ApplicationComposing: Composing where Route == ApplicationRoute {}

struct ApplicationComposer: ApplicationComposing {
    func makeViewController(for route: ApplicationRoute, capability: ComposeCapability) -> UIViewController {
        switch route {
        case .launch(let eventHandler):
            let viewController = LaunchViewController()
            let presenter = LaunchPresenter(
                interactor: LaunchInteractor(service: LaunchService()),
                onEvent: eventHandler
            )
            viewController.output = presenter
            presenter.view = viewController
            return viewController

        case .mainFlow:
            let mainTabsComposer = MainTabsComposer()
            let mainTabsCoordinator = MainTabsCoordinator(composer: mainTabsComposer)
            let mainTabsContainer = TabContainer(coordinator: mainTabsCoordinator)
            configureMainTabsContainer(mainTabsContainer)
            return mainTabsContainer
        }
    }

    private func configureMainTabsContainer(_ container: TabContainer) {
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

        container.tabBar.standardAppearance = appearance
        container.tabBar.scrollEdgeAppearance = appearance
    }
}
