import UIKit

@MainActor
internal struct InlineNavigationDriver {
    internal func flowStack(startingAt rootViewController: UIViewController?) -> [UIViewController] {
        guard let rootViewController else { return [] }
        guard let navigationController = rootViewController.navigationController,
              let rootIndex = navigationController.viewControllers.firstIndex(of: rootViewController) else {
            return [rootViewController]
        }
        return Array(navigationController.viewControllers[rootIndex...])
    }

    internal func replaceRoot(
        with item: RouterItem,
        currentRoot: UIViewController?,
        animated: Bool
    ) -> (newRoot: UIViewController, mutation: NavigationMutation) {
        let oldStack = flowStack(startingAt: currentRoot)
        let newRoot = item.viewController
        guard let currentRoot,
              let navigationController = currentRoot.navigationController,
              let rootIndex = navigationController.viewControllers.firstIndex(of: currentRoot) else {
            return (
                newRoot,
                NavigationMutation.stackDelta(oldStack: oldStack, newStack: [newRoot], newItems: [item])
            )
        }

        let nextNavigationStack = Array(navigationController.viewControllers.prefix(upTo: rootIndex)) + [newRoot]
        navigationController.setViewControllers(nextNavigationStack, animated: animated)
        return (
            newRoot,
            NavigationMutation.stackDelta(oldStack: oldStack, newStack: [newRoot], newItems: [item])
        )
    }

    internal func push(
        _ item: RouterItem,
        from rootViewController: UIViewController?,
        animated: Bool,
        completion: @escaping (NavigationMutation) -> Void
    ) -> UIViewController? {
        let oldStack = flowStack(startingAt: rootViewController)
        let viewController = item.viewController
        guard let rootViewController else {
            completion(NavigationMutation.stackDelta(oldStack: oldStack, newStack: [viewController], newItems: [item]))
            return viewController
        }

        guard let navigationController = rootViewController.navigationController else {
            assertionFailure("Inline FlowRouter: content is not embedded in UINavigationController.")
            return nil
        }

        let driver = self
        navigationController.pushViewController(viewController, animated: animated) { [weak rootViewController] in
            completion(NavigationMutation.stackDelta(
                oldStack: oldStack,
                newStack: driver.flowStack(startingAt: rootViewController),
                newItems: [item]
            ))
        }
        return nil
    }

    internal func pop(
        from rootViewController: UIViewController?,
        animated: Bool,
        completion: @escaping (NavigationMutation) -> Void
    ) -> Bool {
        let oldStack = flowStack(startingAt: rootViewController)
        guard let rootViewController else { return false }
        guard let navigationController = rootViewController.navigationController else {
            assertionFailure("Inline FlowRouter: content is not embedded in UINavigationController.")
            return false
        }

        guard navigationController.topViewController !== rootViewController else {
            assertionFailure("Inline FlowRouter cannot pop its root content.")
            return false
        }

        let driver = self
        navigationController.popViewController(animated: animated) { [weak rootViewController] in
            completion(NavigationMutation.stackDelta(
                oldStack: oldStack,
                newStack: driver.flowStack(startingAt: rootViewController),
                newItems: []
            ))
        }
        return true
    }

    internal func popToRoot(
        from rootViewController: UIViewController?,
        animated: Bool,
        completion: @escaping (NavigationMutation) -> Void
    ) -> Bool {
        guard let rootViewController else { return false }
        return popTo(RouterItem(rootViewController), from: rootViewController, animated: animated, completion: completion)
    }

    internal func popTo(
        _ item: RouterItem,
        from rootViewController: UIViewController?,
        animated: Bool,
        completion: @escaping (NavigationMutation) -> Void
    ) -> Bool {
        let oldStack = flowStack(startingAt: rootViewController)
        guard let rootViewController else { return false }
        guard let navigationController = rootViewController.navigationController,
              let rootIndex = navigationController.viewControllers.firstIndex(of: rootViewController),
              let targetIndex = navigationController.viewControllers.firstIndex(where: { item.isWrapping($0) }) else {
            assertionFailure("Inline FlowRouter: content is not embedded in UINavigationController.")
            return false
        }

        guard targetIndex >= rootIndex else {
            assertionFailure("Inline FlowRouter cannot navigate outside of its flow stack.")
            return false
        }

        let driver = self
        navigationController.popToViewController(item.viewController, animated: animated) { [weak rootViewController] in
            completion(NavigationMutation.stackDelta(
                oldStack: oldStack,
                newStack: driver.flowStack(startingAt: rootViewController),
                newItems: []
            ))
        }
        return true
    }

    internal func setStack(
        _ items: [RouterItem],
        from rootViewController: UIViewController?,
        animated: Bool
    ) -> (newRoot: UIViewController, mutation: NavigationMutation)? {
        guard let first = items.first else { return nil }

        let oldStack = flowStack(startingAt: rootViewController)
        let nextFlowStack = items.map(\.viewController)
        guard let rootViewController,
              canSetStack(from: rootViewController) else {
            let firstViewController = first.viewController
            return (
                firstViewController,
                NavigationMutation.stackDelta(oldStack: oldStack, newStack: [firstViewController], newItems: [first])
            )
        }

        guard let navigationController = rootViewController.navigationController,
              let rootIndex = navigationController.viewControllers.firstIndex(of: rootViewController) else {
            return nil
        }

        let nextNavigationStack = Array(navigationController.viewControllers.prefix(upTo: rootIndex)) + nextFlowStack
        navigationController.setViewControllers(nextNavigationStack, animated: animated)
        return (
            first.viewController,
            NavigationMutation.stackDelta(oldStack: oldStack, newStack: nextFlowStack, newItems: items)
        )
    }

    internal func canSetStack(from rootViewController: UIViewController) -> Bool {
        guard let navigationController = rootViewController.navigationController else {
            return false
        }
        return navigationController.viewControllers.contains(rootViewController)
    }
}
