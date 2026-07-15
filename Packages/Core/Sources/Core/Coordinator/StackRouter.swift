import UIKit

@MainActor
final class StackRouter: BaseRouter<UINavigationController>, StackNavigation {
    var navigationController: UINavigationController {
        guard let nav = parentViewController else {
            fatalError("UINavigationController is not configured in StackRouter")
        }
        return nav
    }

    var items: [RouterItem] {
        childRouterItems
    }

    init(makeNavigationController: () -> UINavigationController = { UINavigationController() }) {
        let nav = makeNavigationController()
        super.init()
        updateParent(RouterItem(nav))
        let dispatcher = NavigationControllerDelegateDispatcher.install(on: nav)
        dispatcher.addDelegate(self, category: .instance)
    }

    func setRoot(_ item: RouterItem, animated: Bool) {
        navigationController.setViewControllers([item.viewController], animated: animated, completion: nil)
        syncChildRouterItems(with: navigationController.viewControllers)
    }

    func push(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        let shouldAnimate = navigationController.viewControllers.isEmpty ? false : animated
        navigationController.pushViewController(item.viewController, animated: shouldAnimate, completion: completion)
        syncChildRouterItems(with: navigationController.viewControllers)
    }

    func pop(animated: Bool, completion: (() -> Void)?) {
        navigationController.popViewController(animated: animated, completion: completion)
        syncChildRouterItems(with: navigationController.viewControllers)
    }

    func popToRoot(animated: Bool, completion: (() -> Void)?) {
        navigationController.popToRootViewController(animated: animated, completion: completion)
        syncChildRouterItems(with: navigationController.viewControllers)
    }

    func popTo(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        guard navigationController.viewControllers.contains(item.viewController) else {
            completion?()
            return
        }
        navigationController.popToViewController(item.viewController, animated: animated, completion: completion)
        syncChildRouterItems(with: navigationController.viewControllers)
    }

    func setStack(_ items: [RouterItem], animated: Bool) {
        navigationController.setViewControllers(items.map(\.viewController), animated: animated, completion: nil)
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
    func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        syncChildRouterItems(with: navigationController.viewControllers)
    }
}
