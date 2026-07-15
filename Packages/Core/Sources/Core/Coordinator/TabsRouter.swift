import UIKit

@MainActor
final class TabsRouter: BaseRouter<UITabBarController> {
    init(makeTabBarController: () -> UITabBarController = { UITabBarController() }) {
        let tab = makeTabBarController()
        super.init()
        updateParent(RouterItem(tab))
    }
    
    // MARK: - Private members
}

extension TabsRouter: TabsNavigation {
    var selectedIndex: Int {
        parent.selectedIndex
    }

    var selectedItem: RouterItem? {
        let index = parent.selectedIndex
        guard index >= 0, index < childRouterItems.count else { return nil }
        return childRouterItems[index]
    }
    
    func setItems(_ items: [RouterItem], animated: Bool) {
        parent.setViewControllers(items.map(\.viewController), animated: animated)
        updateChildren(items)
    }

    func selectTab(at index: Int) {
        parent.selectedIndex = index
    }

    func selectItem(_ item: RouterItem) {
        guard let index = parent.viewControllers?.firstIndex(where: { item.isWrapping($0) }) else {
            return
        }
        parent.selectedIndex = index
    }
}
