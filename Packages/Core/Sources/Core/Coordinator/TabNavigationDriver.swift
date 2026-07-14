import UIKit

@MainActor
internal final class TabNavigationDriver {
    internal init(tabBarController: UITabBarController) {
        self.tabBarController = tabBarController
    }

    internal var selectedIndex: Int {
        requireTabBarController().selectedIndex
    }

    internal var selectedItem: RouterItem? {
        requireTabBarController().selectedViewController.map { RouterItem($0) }
    }

    internal func setItems(
        _ items: [RouterItem],
        animated: Bool
    ) -> NavigationMutation {
        let tabBarController = requireTabBarController()
        let oldViewControllers = tabBarController.viewControllers ?? []
        let viewControllers = items.map(\.viewController)

        tabBarController.setViewControllers(viewControllers, animated: animated)

        return NavigationMutation.stackDelta(
            oldStack: oldViewControllers,
            newStack: viewControllers,
            newItems: items
        )
    }

    internal func selectTab(at index: Int) {
        requireTabBarController().selectedIndex = index
    }

    internal func selectItem(_ item: RouterItem) {
        let tabBarController = requireTabBarController()
        guard let index = tabBarController.viewControllers?.firstIndex(where: { item.isWrapping($0) }) else {
            return
        }
        tabBarController.selectedIndex = index
    }

    private func requireTabBarController() -> UITabBarController {
        guard let tabBarController else {
            fatalError("TabNavigationDriver's tab bar controller was deallocated.")
        }
        return tabBarController
    }

    private weak var tabBarController: UITabBarController?
}
