import UIKit

extension FlowRouter where RootViewController == UITabBarController, Driver == TabNavigationDriver {
    internal convenience init(
        makeTabBarController: @MainActor () -> UITabBarController,
        attachmentManager: any FlowInstanceAttachmentStoring
    ) {
        let tabBarController = makeTabBarController()
        self.init(
            rootViewController: tabBarController,
            driver: TabNavigationDriver(tabBarController: tabBarController),
            attachmentStore: attachmentManager
        )
    }
}

extension FlowRouter where RootViewController == UITabBarController, Driver == TabNavigationDriver {
    /// Индекс активной вкладки в `UITabBarController`.
    var selectedIndex: Int {
        driver.selectedIndex
    }

    /// Текущий выбранный item, если tab bar уже содержит выбранный экран.
    var selectedItem: RouterItem? {
        driver.selectedItem
    }

    func setItems(_ items: [RouterItem], animated: Bool) {
        let mutation = driver.setItems(items, animated: animated)
        applyInstanceMutation(mutation)
    }

    func selectTab(at index: Int) {
        driver.selectTab(at: index)
    }

    func selectItem(_ item: RouterItem) {
        driver.selectItem(item)
    }
}

@MainActor
internal final class TabNavigationFacade {
    internal init(router: FlowRouter<UITabBarController, TabNavigationDriver>) {
        self.router = router
    }

    private let router: FlowRouter<UITabBarController, TabNavigationDriver>
}

extension TabNavigationFacade: TabNavigation {
    var selectedIndex: Int {
        router.selectedIndex
    }

    var selectedItem: RouterItem? {
        router.selectedItem
    }

    func present(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        router.present(item, animated: animated, completion: completion)
    }

    func dismiss(animated: Bool, completion: (() -> Void)?) {
        router.dismiss(animated: animated, completion: completion)
    }

    func setItems(_ items: [RouterItem], animated: Bool) {
        router.setItems(items, animated: animated)
    }

    func selectTab(at index: Int) {
        router.selectTab(at: index)
    }

    func selectItem(_ item: RouterItem) {
        router.selectItem(item)
    }
}
