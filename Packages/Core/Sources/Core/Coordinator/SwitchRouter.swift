import UIKit

typealias SwitchTransitionHandler = @MainActor @Sendable (
    _ oldViewController: UIViewController,
    _ newViewController: UIViewController,
    _ animated: Bool,
    _ completion: @escaping @MainActor @Sendable () -> Void
) -> Bool

@MainActor
final class SwitchRouter: BaseRouter<UIViewController>, SwitchNavigation {
    var rootViewController: UIViewController? {
        subclassParentRouterItem?.viewController
    }

    var currentItem: RouterItem? {
        subclassParentRouterItem
    }

    private var oldContentRetainers: Set<UIViewController> = []
    private var transitionHandler: SwitchTransitionHandler?

    func setTransitionHandler(_ handler: SwitchTransitionHandler?) {
        self.transitionHandler = handler
    }

    func switchTo(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        print("[SwitchRouter] switchTo called for VC: \(item.viewController)")
        let newVC = item.viewController
        guard let oldVC = rootViewController else {
            print("[SwitchRouter] setting initial rootViewController: \(newVC)")
            updateParent(item)
            updateChildren([item])
            completion?()
            return
        }

        updateParent(item)
        oldContentRetainers.insert(oldVC)
        updateChildren([item])

        performTransition(from: oldVC, to: newVC, animated: animated) { [weak self] in
            guard let self else { return }
            self.oldContentRetainers.remove(oldVC)
            completion?()
        }
    }

    private func performTransition(
        from oldVC: UIViewController,
        to newVC: UIViewController,
        animated: Bool,
        completion: @escaping @MainActor @Sendable () -> Void
    ) {
        print("[SwitchRouter] performTransition from: \(oldVC) to: \(newVC)")
        if transitionHandler?(oldVC, newVC, animated, completion) == true {
            print("[SwitchRouter] transition handled by custom handler")
            return
        }

        if let nav = oldVC.navigationController,
           let index = nav.viewControllers.firstIndex(of: oldVC) {
            var viewControllers = nav.viewControllers
            viewControllers[index] = newVC
            nav.setViewControllers(viewControllers, animated: animated, completion: completion)
            return
        }

        if let tab = oldVC.tabBarController,
           let index = tab.viewControllers?.firstIndex(of: oldVC) {
            var viewControllers = tab.viewControllers ?? []
            viewControllers[index] = newVC
            tab.setViewControllers(viewControllers, animated: animated)
            completion()
            return
        }

        let window = oldVC.view.window ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.rootViewController === oldVC }

        if let window {
            transitionInWindow(window, to: newVC, animated: animated, completion: completion)
            return
        }

        completion()
    }

    private func transitionInWindow(
        _ window: UIWindow,
        to newVC: UIViewController,
        animated: Bool,
        completion: @escaping @MainActor @Sendable () -> Void
    ) {
        print("[SwitchRouter] transitionInWindow to: \(newVC), animated: \(animated)")
        guard animated else {
            window.rootViewController = newVC
            completion()
            return
        }

        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
            let animationsEnabled = UIView.areAnimationsEnabled
            UIView.setAnimationsEnabled(false)
            window.rootViewController = newVC
            UIView.setAnimationsEnabled(animationsEnabled)
        } completion: { _ in
            completion()
        }
    }
}
