import UIKit

@MainActor
final class StackRouter: BaseRouter<UINavigationController> {

    init(makeNavigationController: () -> UINavigationController = { UINavigationController() }) {
        let nav = makeNavigationController()
        super.init()
        updateParent(RouterItem(nav))
        nav.addDelegateIfNeeded(self, category: .instance)
    }
    
    // MARK: - Private members

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

extension StackRouter: StackNavigation {
    var items: [RouterItem] {
        childRouterItems
    }
    
    func setRoot(_ item: RouterItem, animated: Bool) {
        parent.setViewControllers([item.viewController], animated: animated, completion: nil)
        syncChildRouterItems(with: parent.viewControllers)
    }

    func push(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        let shouldAnimate = parent.viewControllers.isEmpty ? false : animated
        parent.pushViewController(item.viewController, animated: shouldAnimate, completion: completion)
        syncChildRouterItems(with: parent.viewControllers)
    }

    func pop(animated: Bool, completion: (() -> Void)?) {
        parent.popViewController(animated: animated, completion: completion)
        syncChildRouterItems(with: parent.viewControllers)
    }

    func popToRoot(animated: Bool, completion: (() -> Void)?) {
        parent.popToRootViewController(animated: animated, completion: completion)
        syncChildRouterItems(with: parent.viewControllers)
    }

    func popTo(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        guard parent.viewControllers.contains(item.viewController) else {
            completion?()
            return
        }
        parent.popToViewController(item.viewController, animated: animated, completion: completion)
        syncChildRouterItems(with: parent.viewControllers)
    }

    func setStack(_ items: [RouterItem], animated: Bool) {
        parent.setViewControllers(items.map(\.viewController), animated: animated, completion: nil)
        syncChildRouterItems(with: parent.viewControllers)
    }
}

extension StackRouter: UINavigationControllerDelegate {
    func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        syncChildRouterItems(with: parent.viewControllers)
    }
}
