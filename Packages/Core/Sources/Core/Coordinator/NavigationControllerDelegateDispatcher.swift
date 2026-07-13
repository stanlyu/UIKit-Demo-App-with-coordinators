import UIKit

@MainActor
internal final class NavigationControllerDelegateDispatcher: NSObject {
    internal static func install(on navigationController: UINavigationController) -> NavigationControllerDelegateDispatcher {
        if let dispatcher = navigationController.delegate as? NavigationControllerDelegateDispatcher {
            return dispatcher
        }

        let dispatcher = NavigationControllerDelegateDispatcher()
        if let existingDelegate = navigationController.delegate {
            dispatcher.addDelegate(existingDelegate, category: .external)
        }
        navigationController.delegate = dispatcher
        return dispatcher
    }

    internal func addDelegate(
        _ delegate: any UINavigationControllerDelegate,
        category: DelegateCategory = .external
    ) {
        cleanupDelegates()

        let delegateID = ObjectIdentifier(delegate as AnyObject)
        guard !delegates.contains(where: { $0.id == delegateID }) else { return }
        delegates.append(WeakNavigationControllerDelegate(delegate, category: category))
    }

    internal func removeDelegate(_ delegate: any UINavigationControllerDelegate) {
        let delegateID = ObjectIdentifier(delegate as AnyObject)
        delegates.removeAll { $0.delegate == nil || $0.id == delegateID }
    }

    private func activeDelegates(orderedBy order: DelegateDispatchOrder) -> [any UINavigationControllerDelegate] {
        cleanupDelegates()
        switch order {
        case .registration:
            return delegates.compactMap(\.delegate)
        case .frameworkFirst:
            return activeDelegates(in: [.framework, .external])
        case .externalFirst:
            return activeDelegates(in: [.external, .framework])
        }
    }

    private func activeDelegates(
        in categories: [DelegateCategory]
    ) -> [any UINavigationControllerDelegate] {
        categories.flatMap { category in
            delegates
                .filter { $0.category == category }
                .compactMap(\.delegate)
        }
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
        for delegate in activeDelegates(orderedBy: .registration) {
            delegate.navigationController?(navigationController, willShow: viewController, animated: animated)
        }
    }

    internal func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        for delegate in activeDelegates(orderedBy: .frameworkFirst) {
            delegate.navigationController?(navigationController, didShow: viewController, animated: animated)
        }
    }

    internal func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> (any UIViewControllerAnimatedTransitioning)? {
        for delegate in activeDelegates(orderedBy: .externalFirst) {
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
        for delegate in activeDelegates(orderedBy: .externalFirst) {
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
        for delegate in activeDelegates(orderedBy: .externalFirst) {
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
        for delegate in activeDelegates(orderedBy: .externalFirst) {
            if let preferredOrientation = delegate.navigationControllerPreferredInterfaceOrientationForPresentation?(
                navigationController
            ) {
                return preferredOrientation
            }
        }
        return navigationController.topViewController?.preferredInterfaceOrientationForPresentation ?? .portrait
    }
}

extension NavigationControllerDelegateDispatcher {
    internal enum DelegateCategory {
        case external
        case framework
    }
}

private enum DelegateDispatchOrder {
    case registration
    case frameworkFirst
    case externalFirst
}

private final class WeakNavigationControllerDelegate {
    init(
        _ delegate: any UINavigationControllerDelegate,
        category: NavigationControllerDelegateDispatcher.DelegateCategory
    ) {
        self.id = ObjectIdentifier(delegate as AnyObject)
        self.delegate = delegate
        self.category = category
    }

    let id: ObjectIdentifier
    let category: NavigationControllerDelegateDispatcher.DelegateCategory
    weak var delegate: (any UINavigationControllerDelegate)?
}
