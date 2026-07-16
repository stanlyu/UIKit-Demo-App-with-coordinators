import UIKit

extension RouterProvider {
    /// Создаёт роутер навигации по вкладкам на базе `UITabBarController`.
    ///
    /// - Parameter makeTabBarController: Фабрика контроллера вкладок.
    static func tabs(makeTabBarController: () -> UITabBarController = { UITabBarController() }) -> TabsNavigation & FlowLifecycleRouter {
        TabsRouter(makeTabBarController: makeTabBarController)
    }
}

// Роутер навигации по вкладкам: управляет набором вкладок и выбором активной.
@MainActor
private final class TabsRouter: BaseRouter<UITabBarController> {
    init(makeTabBarController: () -> UITabBarController) {
        let tab = makeTabBarController()
        super.init()
        updateParent(RouterItem(tab))
    }
}

extension TabsRouter: TabsNavigation {
    var selectedIndex: Int {
        parentViewController.selectedIndex
    }

    var selectedItem: RouterItem? {
        let index = parentViewController.selectedIndex
        guard index >= 0, index < childRouterItems.count else { return nil }
        return childRouterItems[index]
    }
    
    func setItems(_ items: [RouterItem], animated: Bool) {
        parentViewController.setViewControllers(items.map(\.viewController), animated: animated)
        updateChildren(items)
    }

    func selectTab(at index: Int) {
        parentViewController.selectedIndex = index
    }

    func selectItem(_ item: RouterItem) {
        guard let index = parentViewController.viewControllers?.firstIndex(where: { item.isWrapping($0) }) else {
            return
        }
        parentViewController.selectedIndex = index
    }
}
