import UIKit

@MainActor
internal final class StackFlowRouter: BaseFlowRouter<UINavigationController> {
    internal init(makeNavigationController: @MainActor () -> UINavigationController) {
        let navigationController = makeNavigationController()
        super.init(rootViewController: navigationController)
    }

    private func requireNavigationController() -> UINavigationController {
        guard let navigationController = rootViewController else {
            fatalError("StackFlowRouter's navigation controller was deallocated.")
        }
        return navigationController
    }
}

extension StackFlowRouter {
    func present(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        requireNavigationController().present(viewController(for: item), animated: animated, completion: completion)
    }

    func dismiss(animated: Bool, completion: (() -> Void)?) {
        requireNavigationController().dismiss(animated: animated, completion: completion)
    }
}

extension StackFlowRouter: StackNavigation {
    var items: [RouterItem] {
        requireNavigationController().viewControllers.map { RouterItem($0) }
    }

    func setRoot(_ item: RouterItem, animated: Bool) {
        requireNavigationController().setViewControllers([viewController(for: item)], animated: animated)
    }

    func push(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        let navigationController = requireNavigationController()
        let shouldAnimate = navigationController.viewControllers.isEmpty ? false : animated
        navigationController.pushViewController(viewController(for: item), animated: shouldAnimate, completion: completion)
    }

    func pop(animated: Bool, completion: (() -> Void)?) {
        requireNavigationController().popViewController(animated: animated, completion: completion)
    }

    func popToRoot(animated: Bool, completion: (() -> Void)?) {
        requireNavigationController().popToRootViewController(animated: animated, completion: completion)
    }

    func popTo(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        requireNavigationController().popToViewController(viewController(for: item), animated: animated, completion: completion)
    }

    func setStack(_ items: [RouterItem], animated: Bool) {
        requireNavigationController().setViewControllers(viewControllers(for: items), animated: animated)
    }
}

@MainActor
internal final class TabFlowRouter: BaseFlowRouter<UITabBarController> {
    internal init(makeTabBarController: @MainActor () -> UITabBarController) {
        let tabBarController = makeTabBarController()
        super.init(rootViewController: tabBarController)
    }

    private func requireTabBarController() -> UITabBarController {
        guard let tabBarController = rootViewController else {
            fatalError("TabFlowRouter's tab bar controller was deallocated.")
        }
        return tabBarController
    }
}

extension TabFlowRouter {
    func present(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        requireTabBarController().present(viewController(for: item), animated: animated, completion: completion)
    }

    func dismiss(animated: Bool, completion: (() -> Void)?) {
        requireTabBarController().dismiss(animated: animated, completion: completion)
    }
}

extension TabFlowRouter: TabNavigation {
    var selectedIndex: Int {
        requireTabBarController().selectedIndex
    }

    var selectedItem: RouterItem? {
        requireTabBarController().selectedViewController.map { RouterItem($0) }
    }

    func setItems(_ items: [RouterItem], animated: Bool) {
        requireTabBarController().setViewControllers(viewControllers(for: items), animated: animated)
    }

    func selectTab(at index: Int) {
        requireTabBarController().selectedIndex = index
    }

    func selectItem(_ item: RouterItem) {
        let tabBarController = requireTabBarController()
        guard let index = tabBarController.viewControllers?.firstIndex(where: { item.isWrapping($0) }) else {
            return
        }
        tabBarController.selectedIndex = index
    }
}

@MainActor
internal final class InlineFlowRouter: BaseFlowRouter<UIViewController> {
    private func setContent(_ viewController: UIViewController) {
        setRootViewController(viewController)
    }

    private func requireContentViewController() -> UIViewController {
        guard let contentViewController else {
            fatalError("InlineFlowRouter has no root content.")
        }
        return contentViewController
    }

    private var contentViewController: UIViewController? {
        rootViewController
    }
}

extension InlineFlowRouter {
    func present(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        requireContentViewController().present(viewController(for: item), animated: animated, completion: completion)
    }

    func dismiss(animated: Bool, completion: (() -> Void)?) {
        requireContentViewController().dismiss(animated: animated, completion: completion)
    }
}

extension InlineFlowRouter: StackNavigation {
    var items: [RouterItem] {
        guard let contentViewController else { return [] }
        guard let navigationController = contentViewController.navigationController else {
            return [RouterItem(contentViewController)]
        }
        guard let rootIndex = navigationController.viewControllers.firstIndex(of: contentViewController) else {
            return [RouterItem(contentViewController)]
        }
        return navigationController.viewControllers[rootIndex...].map { RouterItem($0) }
    }

    func setRoot(_ item: RouterItem, animated: Bool) {
        let viewController = viewController(for: item)

        guard let contentViewController else {
            setContent(viewController)
            return
        }

        guard let navigationController = contentViewController.navigationController,
              let rootIndex = navigationController.viewControllers.firstIndex(of: contentViewController) else {
            setContent(viewController)
            return
        }

        let previousStack = navigationController.viewControllers.prefix(upTo: rootIndex)
        navigationController.setViewControllers(Array(previousStack) + [viewController], animated: animated)
        setContent(viewController)
    }

    func push(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        let viewController = viewController(for: item)

        guard let contentViewController else {
            setContent(viewController)
            completion?()
            return
        }

        guard let navigationController = contentViewController.navigationController else {
            assertionFailure("InlineFlowRouter: content is not embedded in UINavigationController.")
            return
        }

        navigationController.pushViewController(viewController, animated: animated, completion: completion)
    }

    func pop(animated: Bool, completion: (() -> Void)?) {
        guard let navigationController = contentViewController?.navigationController,
              let contentViewController else {
            assertionFailure("InlineFlowRouter: content is not embedded in UINavigationController.")
            return
        }

        guard navigationController.topViewController !== contentViewController else {
            assertionFailure("InlineFlowRouter cannot pop its root content.")
            return
        }

        navigationController.popViewController(animated: animated, completion: completion)
    }

    func popToRoot(animated: Bool, completion: (() -> Void)?) {
        guard let contentViewController else { return }
        popTo(RouterItem(contentViewController), animated: animated, completion: completion)
    }

    func popTo(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        guard let navigationController = contentViewController?.navigationController,
              let contentViewController,
              let rootIndex = navigationController.viewControllers.firstIndex(of: contentViewController),
              let targetIndex = navigationController.viewControllers.firstIndex(where: { item.isWrapping($0) }) else {
            assertionFailure("InlineFlowRouter: content is not embedded in UINavigationController.")
            return
        }

        guard targetIndex >= rootIndex else {
            assertionFailure("InlineFlowRouter cannot navigate outside of its flow stack.")
            return
        }

        navigationController.popToViewController(viewController(for: item), animated: animated, completion: completion)
    }

    func setStack(_ items: [RouterItem], animated: Bool) {
        guard let first = items.first else { return }
        let firstViewController = viewController(for: first)

        if contentViewController == nil {
            setContent(firstViewController)
        }

        guard let navigationController = contentViewController?.navigationController,
              let contentViewController,
              let rootIndex = navigationController.viewControllers.firstIndex(of: contentViewController) else {
            assertionFailure("InlineFlowRouter: content is not embedded in UINavigationController.")
            return
        }

        var nextStack = Array(navigationController.viewControllers.prefix(upTo: rootIndex + 1))
        nextStack.append(contentsOf: viewControllers(for: Array(items.dropFirst())))
        navigationController.setViewControllers(nextStack, animated: animated)
    }
}

@MainActor
internal final class SwitchFlowRouter: BaseFlowRouter<UIViewController> {
    internal var onRootChanged: (@MainActor (UIViewController) -> Void)?

    private var oldContentRetainer: UIViewController?

    private func setInitialContent(_ viewController: UIViewController) {
        setRootViewController(viewController)
    }

    private func requireCurrentContent() -> UIViewController {
        guard let viewController = rootViewController else {
            fatalError("SwitchFlowRouter has no root content.")
        }
        return viewController
    }

    private func performTransition(
        from oldViewController: UIViewController,
        to newViewController: UIViewController,
        animated: Bool,
        completion: @escaping () -> Void
    ) {
        if let window = oldViewController.view.window {
            transitionInWindow(window, to: newViewController, animated: animated, completion: completion)
            return
        }

        if let navigationController = oldViewController.navigationController,
           let index = navigationController.viewControllers.firstIndex(of: oldViewController) {
            var viewControllers = navigationController.viewControllers
            viewControllers[index] = newViewController
            navigationController.setViewControllers(viewControllers, animated: animated, completion: completion)
            return
        }

        if let tabBarController = oldViewController.tabBarController,
           let index = tabBarController.viewControllers?.firstIndex(of: oldViewController) {
            var viewControllers = tabBarController.viewControllers ?? []
            viewControllers[index] = newViewController
            tabBarController.setViewControllers(viewControllers, animated: animated)
            completion()
            return
        }

        completion()
    }

    private func transitionInWindow(
        _ window: UIWindow,
        to newViewController: UIViewController,
        animated: Bool,
        completion: @escaping () -> Void
    ) {
        guard animated else {
            window.rootViewController = newViewController
            completion()
            return
        }

        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
            let animationsEnabled = UIView.areAnimationsEnabled
            UIView.setAnimationsEnabled(false)
            window.rootViewController = newViewController
            UIView.setAnimationsEnabled(animationsEnabled)
        } completion: { _ in
            completion()
        }
    }
}

extension SwitchFlowRouter {
    func present(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        requireCurrentContent().present(viewController(for: item), animated: animated, completion: completion)
    }

    func dismiss(animated: Bool, completion: (() -> Void)?) {
        requireCurrentContent().dismiss(animated: animated, completion: completion)
    }
}

extension SwitchFlowRouter: SwitchNavigation {
    var currentItem: RouterItem? {
        rootViewController.map { RouterItem($0) }
    }

    func switchTo(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        let newViewController = viewController(for: item)

        guard let oldViewController = rootViewController else {
            setInitialContent(newViewController)
            onRootChanged?(newViewController)
            completion?()
            return
        }

        setRootViewController(newViewController)
        oldContentRetainer = oldViewController
        onRootChanged?(newViewController)

        performTransition(from: oldViewController, to: newViewController, animated: animated) { [weak self] in
            self?.oldContentRetainer = nil
            completion?()
        }
    }
}
