import UIKit

extension RouterProvider {
    static func inline() -> StackNavigation & FlowLifecycleRouter {
        InlineRouter()
    }
}

@MainActor
private final class InlineRouter: BaseRouter<UIViewController> {
    func syncChildRouterItems() {
        let rootVC = parentViewController
        let currentStack: [UIViewController]
        
        if let nav = parentViewController.navigationController,
           let rootIndex = nav.viewControllers.firstIndex(of: rootVC) {
            nav.addDelegateIfNeeded(self, category: .instance)
            // В дочерние элементы складываем всё, что идет ПОСЛЕ rootVC
            currentStack = Array(nav.viewControllers.suffix(from: rootIndex + 1))
        } else {
            currentStack = []
        }
        
        let updatedItems = currentStack.map { vc in
            if let existing = childRouterItems.first(where: { $0.isWrapping(vc) }) {
                return existing
            } else {
                return RouterItem(vc)
            }
        }
        updateChildren(updatedItems)
    }
}

extension InlineRouter: StackNavigation {
    var items: [RouterItem] {
        [parentRouterItem].compactMap { $0 } + childRouterItems
    }

    func setRoot(_ item: RouterItem, animated: Bool) {
        let oldRoot = parentRouterItem?.viewController
        updateParent(item)
        
        if let oldRoot,
           let nav = oldRoot.navigationController {
            nav.addDelegateIfNeeded(self, category: .instance)
            if let rootIndex = nav.viewControllers.firstIndex(of: oldRoot) {
                let nextNavigationStack = Array(nav.viewControllers.prefix(upTo: rootIndex)) + [item.viewController]
                nav.setViewControllers(nextNavigationStack, animated: animated, completion: nil)
            }
        }
        syncChildRouterItems()
    }

    func push(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        guard let nav = parentViewController.navigationController else {
            assertionFailure("Inline Router: content is not embedded in UINavigationController.")
            completion?()
            return
        }
        nav.addDelegateIfNeeded(self, category: .instance)
        nav.pushViewController(item.viewController, animated: animated, completion: completion)
        syncChildRouterItems()
    }

    func pop(animated: Bool, completion: (() -> Void)?) {
        let rootVC = parentViewController
        guard let nav = parentViewController.navigationController else {
            completion?()
            return
        }
        nav.addDelegateIfNeeded(self, category: .instance)
        guard nav.topViewController !== rootVC else {
            assertionFailure("Inline Router cannot pop its root content.")
            completion?()
            return
        }
        nav.popViewController(animated: animated, completion: completion)
        syncChildRouterItems()
    }

    func popToRoot(animated: Bool, completion: (() -> Void)?) {
        popTo(RouterItem(parentViewController), animated: animated, completion: completion)
    }

    func popTo(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        let rootVC = parentViewController
        guard let nav = parentViewController.navigationController,
              let rootIndex = nav.viewControllers.firstIndex(of: rootVC),
              let targetIndex = nav.viewControllers.firstIndex(of: item.viewController) else {
            completion?()
            return
        }
        nav.addDelegateIfNeeded(self, category: .instance)
        guard targetIndex >= rootIndex else {
            assertionFailure("Inline Router cannot navigate outside of its flow stack.")
            completion?()
            return
        }
        nav.popToViewController(item.viewController, animated: animated, completion: completion)
        syncChildRouterItems()
    }

    func setStack(_ items: [RouterItem], animated: Bool) {
        guard let firstItem = items.first else { return }
        let oldRoot = parentRouterItem?.viewController
        updateParent(firstItem)
        
        if let oldRoot,
           let nav = oldRoot.navigationController {
            nav.addDelegateIfNeeded(self, category: .instance)
            if let rootIndex = nav.viewControllers.firstIndex(of: oldRoot) {
                let nextNavigationStack = Array(nav.viewControllers.prefix(upTo: rootIndex)) + items.map(\.viewController)
                nav.setViewControllers(nextNavigationStack, animated: animated, completion: nil)
            }
        }
        syncChildRouterItems()
    }
}

extension InlineRouter: UINavigationControllerDelegate {
    func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        syncChildRouterItems()
    }
}
