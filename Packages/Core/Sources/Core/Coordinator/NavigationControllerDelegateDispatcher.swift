import UIKit

@MainActor
internal final class NavigationControllerDelegateDispatcher: NSObject {
    internal static func install(on navigationController: UINavigationController) -> NavigationControllerDelegateDispatcher {
        if let dispatcher = navigationController.delegate as? NavigationControllerDelegateDispatcher {
            return dispatcher
        }

        let dispatcher = NavigationControllerDelegateDispatcher()
        if let existingDelegate = navigationController.delegate {
            dispatcher.addDelegate(existingDelegate)
        }
        navigationController.delegate = dispatcher
        return dispatcher
    }

    internal func addDelegate(_ delegate: any UINavigationControllerDelegate) {
        cleanupDelegates()

        let delegateID = ObjectIdentifier(delegate as AnyObject)
        guard !delegates.contains(where: { $0.id == delegateID }) else { return }
        delegates.append(WeakNavigationControllerDelegate(delegate))
    }

    internal func removeDelegate(_ delegate: any UINavigationControllerDelegate) {
        let delegateID = ObjectIdentifier(delegate as AnyObject)
        delegates.removeAll { $0.delegate == nil || $0.id == delegateID }
    }

    private var activeDelegates: [any UINavigationControllerDelegate] {
        cleanupDelegates()
        return delegates.compactMap(\.delegate)
    }

    private func cleanupDelegates() {
        delegates.removeAll { $0.delegate == nil }
    }

    private var delegates: [WeakNavigationControllerDelegate] = []
}

extension NavigationControllerDelegateDispatcher: UINavigationControllerDelegate {
    internal func navigationController(
        _ navigationController: UINavigationController,
        willShow viewController: UIViewController,
        animated: Bool
    ) {
        for delegate in activeDelegates {
            delegate.navigationController?(navigationController, willShow: viewController, animated: animated)
        }
    }

    internal func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        for delegate in activeDelegates {
            delegate.navigationController?(navigationController, didShow: viewController, animated: animated)
        }
    }

    internal func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> (any UIViewControllerAnimatedTransitioning)? {
        for delegate in activeDelegates.reversed() {
            if let animator = delegate.navigationController?(
                navigationController,
                animationControllerFor: operation,
                from: fromVC,
                to: toVC
            ) {
                return animator
            }
        }
        return nil
    }

    internal func navigationController(
        _ navigationController: UINavigationController,
        interactionControllerFor animationController: any UIViewControllerAnimatedTransitioning
    ) -> (any UIViewControllerInteractiveTransitioning)? {
        for delegate in activeDelegates.reversed() {
            if let interactionController = delegate.navigationController?(
                navigationController,
                interactionControllerFor: animationController
            ) {
                return interactionController
            }
        }
        return nil
    }

    internal func navigationControllerSupportedInterfaceOrientations(
        _ navigationController: UINavigationController
    ) -> UIInterfaceOrientationMask {
        for delegate in activeDelegates {
            if let supportedOrientations = delegate.navigationControllerSupportedInterfaceOrientations?(
                navigationController
            ) {
                return supportedOrientations
            }
        }
        return navigationController.topViewController?.supportedInterfaceOrientations ?? .allButUpsideDown
    }

    internal func navigationControllerPreferredInterfaceOrientationForPresentation(
        _ navigationController: UINavigationController
    ) -> UIInterfaceOrientation {
        for delegate in activeDelegates {
            if let preferredOrientation = delegate.navigationControllerPreferredInterfaceOrientationForPresentation?(
                navigationController
            ) {
                return preferredOrientation
            }
        }
        return navigationController.topViewController?.preferredInterfaceOrientationForPresentation ?? .portrait
    }
}

private final class WeakNavigationControllerDelegate {
    init(_ delegate: any UINavigationControllerDelegate) {
        self.id = ObjectIdentifier(delegate as AnyObject)
        self.delegate = delegate
    }

    let id: ObjectIdentifier
    weak var delegate: (any UINavigationControllerDelegate)?
}
