import UIKit

extension RouterProvider {
    /// Создаёт роутер, управляющий собственным `UINavigationController`.
    ///
    /// - Parameter makeNavigationController: Фабрика навигационного контроллера.
    static func stack(
        makeNavigationController: () -> UINavigationController = { UINavigationController() }
    ) -> StackNavigation & FlowLifecycleRouter {
        StackRouter(makeNavigationController: makeNavigationController)
    }
}

/// Роутер стековой навигации на базе `UINavigationController`. Подписывается на
/// событие `didShow`, чтобы держать дочерние элементы в синхронизации с реальным
/// стеком контроллеров (включая системное «назад» и свайп-back).
@MainActor
private final class StackRouter: BaseRouter<UINavigationController> {

    init(makeNavigationController: () -> UINavigationController = { UINavigationController() }) {
        let nav = makeNavigationController()
        super.init()
        updateParent(RouterItem(nav))
        nav.addDelegateIfNeeded(self, category: .internal)
    }
    
    // MARK: - Private members

    func syncChildRouterItems(with newStack: [UIViewController]) {
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
        parentViewController.setViewControllers([item.viewController], animated: animated, completion: nil)
        syncChildRouterItems(with: parentViewController.viewControllers)
    }

    func push(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        let shouldAnimate = parentViewController.viewControllers.isEmpty ? false : animated
        parentViewController.pushViewController(item.viewController, animated: shouldAnimate, completion: completion)
        syncChildRouterItems(with: parentViewController.viewControllers)
    }

    func pop(animated: Bool, completion: (() -> Void)?) {
        parentViewController.popViewController(animated: animated, completion: completion)
        syncChildRouterItems(with: parentViewController.viewControllers)
    }

    func popToRoot(animated: Bool, completion: (() -> Void)?) {
        parentViewController.popToRootViewController(animated: animated, completion: completion)
        syncChildRouterItems(with: parentViewController.viewControllers)
    }

    func popTo(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        guard parentViewController.viewControllers.contains(item.viewController) else {
            completion?()
            return
        }
        parentViewController.popToViewController(item.viewController, animated: animated, completion: completion)
        syncChildRouterItems(with: parentViewController.viewControllers)
    }

    func setStack(_ items: [RouterItem], animated: Bool) {
        parentViewController.setViewControllers(items.map(\.viewController), animated: animated, completion: nil)
        syncChildRouterItems(with: parentViewController.viewControllers)
    }
}

extension StackRouter: UINavigationControllerDelegate {
    func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        syncChildRouterItems(with: parentViewController.viewControllers)
    }
}
