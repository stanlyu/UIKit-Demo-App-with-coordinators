import UIKit

@MainActor
final class InlineRouter: BaseRouter<UIViewController>, StackNavigation {
    var rootViewController: UIViewController? {
        parentViewController
    }

    var items: [RouterItem] {
        childRouterItems
    }

    private var navigationController: UINavigationController? {
        rootViewController?.navigationController
    }

    func updateRootViewController(_ vc: UIViewController) {
        updateParent(RouterItem(vc))
        if let nav = vc.navigationController {
            let dispatcher = NavigationControllerDelegateDispatcher.install(on: nav)
            dispatcher.addDelegate(self, category: .instance)
        }
        syncChildRouterItems()
    }

    func setRoot(_ item: RouterItem, animated: Bool) {
        let oldRoot = rootViewController
        updateParent(item)
        
        if let oldRoot,
           let nav = oldRoot.navigationController,
           let rootIndex = nav.viewControllers.firstIndex(of: oldRoot) {
            let nextNavigationStack = Array(nav.viewControllers.prefix(upTo: rootIndex)) + [item.viewController]
            nav.setViewControllers(nextNavigationStack, animated: animated) { [weak self] in
                self?.syncChildRouterItems()
            }
        }
        syncChildRouterItems()
    }

    func push(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        guard let nav = navigationController else {
            assertionFailure("Inline Router: content is not embedded in UINavigationController.")
            completion?()
            return
        }
        
        nav.pushViewController(item.viewController, animated: animated) { [weak self] in
            self?.syncChildRouterItems()
            completion?()
        }
        syncChildRouterItems()
    }

    func pop(animated: Bool, completion: (() -> Void)?) {
        guard let rootVC = rootViewController,
              let nav = navigationController else {
            completion?()
            return
        }
        
        guard nav.topViewController !== rootVC else {
            assertionFailure("Inline Router cannot pop its root content.")
            completion?()
            return
        }
        
        nav.popViewController(animated: animated) { [weak self] in
            self?.syncChildRouterItems()
            completion?()
        }
        syncChildRouterItems()
    }

    func popToRoot(animated: Bool, completion: (() -> Void)?) {
        guard let rootVC = rootViewController else {
            completion?()
            return
        }
        popTo(RouterItem(rootVC), animated: animated, completion: completion)
    }

    func popTo(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        guard let rootVC = rootViewController,
              let nav = navigationController,
              let rootIndex = nav.viewControllers.firstIndex(of: rootVC),
              let targetIndex = nav.viewControllers.firstIndex(of: item.viewController) else {
            completion?()
            return
        }
        
        guard targetIndex >= rootIndex else {
            assertionFailure("Inline Router cannot navigate outside of its flow stack.")
            completion?()
            return
        }
        
        nav.popToViewController(item.viewController, animated: animated) { [weak self] in
            self?.syncChildRouterItems()
            completion?()
        }
        syncChildRouterItems()
    }

    func setStack(_ items: [RouterItem], animated: Bool) {
        guard let firstItem = items.first else { return }
        let oldRoot = rootViewController
        updateParent(firstItem)
        
        if let oldRoot,
           let nav = oldRoot.navigationController,
           let rootIndex = nav.viewControllers.firstIndex(of: oldRoot) {
            let nextNavigationStack = Array(nav.viewControllers.prefix(upTo: rootIndex)) + items.map(\.viewController)
            nav.setViewControllers(nextNavigationStack, animated: animated) { [weak self] in
                self?.syncChildRouterItems()
            }
        }
        syncChildRouterItems()
    }

    private func syncChildRouterItems() {
        guard let rootVC = rootViewController else { return }
        let currentStack: [UIViewController]
        if let nav = navigationController,
           let rootIndex = nav.viewControllers.firstIndex(of: rootVC) {
            currentStack = Array(nav.viewControllers[rootIndex...])
        } else {
            currentStack = [rootVC]
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

extension InlineRouter: UINavigationControllerDelegate {
    func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        syncChildRouterItems()
    }
}
