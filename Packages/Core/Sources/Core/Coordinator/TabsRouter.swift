import UIKit

@MainActor
public final class TabsRouter: BaseRouter, TabsNavigation {
    public let tabBarController: UITabBarController

    public var selectedIndex: Int {
        tabBarController.selectedIndex
    }

    public var selectedItem: RouterItem? {
        tabBarController.selectedViewController.map { vc in
            if let existing = childRouterItems.first(where: { $0.isWrapping(vc) }) {
                return existing
            } else {
                return RouterItem(vc)
            }
        }
    }

    public init(makeTabBarController: () -> UITabBarController = { UITabBarController() }) {
        self.tabBarController = makeTabBarController()
        super.init()
    }

    public func setItems(_ items: [RouterItem], animated: Bool) {
        tabBarController.setViewControllers(items.map(\.viewController), animated: animated)
        updateChildren(items)
    }

    public func selectTab(at index: Int) {
        tabBarController.selectedIndex = index
    }

    public func selectItem(_ item: RouterItem) {
        guard let index = tabBarController.viewControllers?.firstIndex(where: { item.isWrapping($0) }) else {
            return
        }
        tabBarController.selectedIndex = index
    }
}
