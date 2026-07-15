import UIKit

@MainActor
final class TabsRouter: BaseRouter<UITabBarController>, TabsNavigation {
    var tabBarController: UITabBarController {
        guard let tab = parentViewController else {
            fatalError("UITabBarController is not configured in TabsRouter")
        }
        return tab
    }

    var selectedIndex: Int {
        tabBarController.selectedIndex
    }

    var selectedItem: RouterItem? {
        let index = tabBarController.selectedIndex
        guard index >= 0, index < childRouterItems.count else { return nil }
        return childRouterItems[index]
    }

    init(makeTabBarController: () -> UITabBarController = { UITabBarController() }) {
        let tab = makeTabBarController()
        super.init()
        updateParent(RouterItem(tab))
    }

    func setItems(_ items: [RouterItem], animated: Bool) {
        tabBarController.setViewControllers(items.map(\.viewController), animated: animated)
        updateChildren(items)
    }

    func selectTab(at index: Int) {
        tabBarController.selectedIndex = index
    }

    func selectItem(_ item: RouterItem) {
        guard let index = tabBarController.viewControllers?.firstIndex(where: { item.isWrapping($0) }) else {
            return
        }
        tabBarController.selectedIndex = index
    }
}
