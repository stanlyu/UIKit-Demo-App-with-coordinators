import UIKit

@MainActor
public final class StackRouter: BaseRouter<UINavigationController>, StackNavigation {
    public var navigationController: UINavigationController {
        guard let nav = parentViewController else {
            fatalError("UINavigationController is not configured in StackRouter")
        }
        return nav
    }

    public var items: [RouterItem] {
        childRouterItems
    }

    public init(makeNavigationController: () -> UINavigationController = { UINavigationController() }) {
        let nav = makeNavigationController()
        super.init()
        updateParent(RouterItem(nav))
        let dispatcher = NavigationControllerDelegateDispatcher.install(on: nav)
        dispatcher.addDelegate(self, category: .instance)
    }

    public func setRoot(_ item: RouterItem, animated: Bool) {
        navigationController.setViewControllers([item.viewController], animated: animated) { [weak self] in
            self?.syncChildRouterItems(with: self?.navigationController.viewControllers ?? [])
        }
        syncChildRouterItems(with: navigationController.viewControllers)
    }

    public func push(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        let shouldAnimate = navigationController.viewControllers.isEmpty ? false : animated
        navigationController.pushViewController(item.viewController, animated: shouldAnimate) { [weak self] in
            self?.syncChildRouterItems(with: self?.navigationController.viewControllers ?? [])
            completion?()
        }
        syncChildRouterItems(with: navigationController.viewControllers)
    }

    public func pop(animated: Bool, completion: (() -> Void)?) {
        navigationController.popViewController(animated: animated) { [weak self] in
            self?.syncChildRouterItems(with: self?.navigationController.viewControllers ?? [])
            completion?()
        }
        syncChildRouterItems(with: navigationController.viewControllers)
    }

    public func popToRoot(animated: Bool, completion: (() -> Void)?) {
        navigationController.popToRootViewController(animated: animated) { [weak self] in
            self?.syncChildRouterItems(with: self?.navigationController.viewControllers ?? [])
            completion?()
        }
        syncChildRouterItems(with: navigationController.viewControllers)
    }

    public func popTo(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        guard navigationController.viewControllers.contains(item.viewController) else {
            completion?()
            return
        }
        navigationController.popToViewController(item.viewController, animated: animated) { [weak self] in
            self?.syncChildRouterItems(with: self?.navigationController.viewControllers ?? [])
            completion?()
        }
        syncChildRouterItems(with: navigationController.viewControllers)
    }

    public func setStack(_ items: [RouterItem], animated: Bool) {
        navigationController.setViewControllers(items.map(\.viewController), animated: animated) { [weak self] in
            self?.syncChildRouterItems(with: self?.navigationController.viewControllers ?? [])
        }
        syncChildRouterItems(with: navigationController.viewControllers)
    }

    private func syncChildRouterItems(with newStack: [UIViewController]) {
        let updatedItems = newStack.map { vc in
            if let existing = childRouterItems.first(where: { $0.isWrapping(vc) }) {
                return existing
            } else {
                return RouterItem(vc)
            }
        }
        updateChildren(updatedItems)
    }
}

extension StackRouter: UINavigationControllerDelegate {
    public func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        syncChildRouterItems(with: navigationController.viewControllers)
    }
}
