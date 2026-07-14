import UIKit

internal typealias SwitchTransitionHandler = (
    _ oldViewController: UIViewController,
    _ newViewController: UIViewController,
    _ animated: Bool,
    _ completion: @escaping () -> Void
) -> Bool

@MainActor
internal final class SwitchNavigationDriver {
    internal func setTransitionHandler(_ handler: SwitchTransitionHandler?) {
        transitionHandler = handler
    }

    internal func switchTo(
        _ item: RouterItem,
        currentRoot oldViewController: UIViewController?,
        animated: Bool,
        updateRoot: (UIViewController, NavigationMutation) -> Void,
        completion: @escaping (NavigationMutation) -> Void
    ) {
        let newViewController = item.viewController

        guard let oldViewController else {
            updateRoot(
                newViewController,
                NavigationMutation.stackDelta(oldStack: [], newStack: [newViewController], newItems: [item])
            )
            completion(NavigationMutation())
            return
        }

        oldContentRetainer = oldViewController
        updateRoot(newViewController, NavigationMutation(insertedItems: [item]))

        performTransition(from: oldViewController, to: newViewController, animated: animated) { [weak self] in
            self?.oldContentRetainer = nil
            completion(NavigationMutation(removedViewControllers: [oldViewController]))
        }
    }

    internal func performTransition(
        from oldViewController: UIViewController,
        to newViewController: UIViewController,
        animated: Bool,
        completion: @escaping () -> Void
    ) {
        if transitionHandler?(oldViewController, newViewController, animated, completion) == true {
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

        if let window = oldViewController.view.window,
           window.rootViewController === oldViewController {
            transitionInWindow(window, to: newViewController, animated: animated, completion: completion)
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

    private var oldContentRetainer: UIViewController?
    private var transitionHandler: SwitchTransitionHandler?
}
