import UIKit

@MainActor
final class NavigationControllerDelegateDispatcher: NSObject {
    // UINavigationController умеет хранить только одного delegate.
    // Dispatcher оставляет внешний delegate на месте логически, но пропускает
    // через себя события, которые нужны Core для синхронизации дерева FlowInstance.
    static func install(on navigationController: UINavigationController) -> NavigationControllerDelegateDispatcher {
        if let dispatcher = navigationController.delegate as? NavigationControllerDelegateDispatcher {
            return dispatcher
        }

        let dispatcher = NavigationControllerDelegateDispatcher()
        if let existingDelegate = navigationController.delegate {
            dispatcher.addDelegate(existingDelegate, category: .application)
        }
        navigationController.delegate = dispatcher
        return dispatcher
    }

    func addDelegate(
        _ delegate: any UINavigationControllerDelegate,
        category: DelegateCategory = .application
    ) {
        removeReleasedDelegates()

        let delegateID = ObjectIdentifier(delegate as AnyObject)
        guard !delegates.contains(where: { $0.id == delegateID }) else { return }
        delegates.append(WeakNavigationControllerDelegate(delegate, category: category))
    }

    func removeDelegate(_ delegate: any UINavigationControllerDelegate) {
        let delegateID = ObjectIdentifier(delegate as AnyObject)
        delegates.removeAll { $0.delegate == nil || $0.id == delegateID }
    }

    private func activeDelegates(orderedBy order: DelegateDispatchOrder) -> [any UINavigationControllerDelegate] {
        removeReleasedDelegates()
        switch order {
        case .registration:
            // willShow остается в порядке регистрации: Core не меняет состояние дерева на willShow.
            return delegates.compactMap(\.delegate)
        case .instanceFirst:
            // didShow сначала нужен Core: после native back application delegate
            // должен читать уже обновленное дерево FlowInstance.
            return activeDelegates(in: [.instance, .application])
        case .applicationFirst:
            // Анимации и ориентации принадлежат приложению, поэтому application delegate
            // получает приоритет над instance observer-ом Core.
            return activeDelegates(in: [.application, .instance])
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

    private func removeReleasedDelegates() {
        delegates.removeAll { $0.delegate == nil }
    }

    private var delegates: [WeakNavigationControllerDelegate] = []
}

extension NavigationControllerDelegateDispatcher: UINavigationControllerDelegate {
    func navigationController(
        _ navigationController: UINavigationController,
        willShow viewController: UIViewController,
        animated: Bool
    ) {
        for delegate in activeDelegates(orderedBy: .registration) {
            delegate.navigationController?(navigationController, willShow: viewController, animated: animated)
        }
    }

    func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        for delegate in activeDelegates(orderedBy: .instanceFirst) {
            delegate.navigationController?(navigationController, didShow: viewController, animated: animated)
        }
    }

    func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> (any UIViewControllerAnimatedTransitioning)? {
        for delegate in activeDelegates(orderedBy: .applicationFirst) {
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

    func navigationController(
        _ navigationController: UINavigationController,
        interactionControllerFor animationController: any UIViewControllerAnimatedTransitioning
    ) -> (any UIViewControllerInteractiveTransitioning)? {
        for delegate in activeDelegates(orderedBy: .applicationFirst) {
            if let interactionController = delegate.navigationController?(
                navigationController,
                interactionControllerFor: animationController
            ) {
                return interactionController
            }
        }
        return nil
    }

    func navigationControllerSupportedInterfaceOrientations(
        _ navigationController: UINavigationController
    ) -> UIInterfaceOrientationMask {
        for delegate in activeDelegates(orderedBy: .applicationFirst) {
            if let supportedOrientations = delegate.navigationControllerSupportedInterfaceOrientations?(
                navigationController
            ) {
                return supportedOrientations
            }
        }
        return navigationController.topViewController?.supportedInterfaceOrientations ?? .allButUpsideDown
    }

    func navigationControllerPreferredInterfaceOrientationForPresentation(
        _ navigationController: UINavigationController
    ) -> UIInterfaceOrientation {
        for delegate in activeDelegates(orderedBy: .applicationFirst) {
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
    enum DelegateCategory {
        /// Delegate, который приложение уже назначило на `UINavigationController`.
        case application
        /// Внутренний observer Core для cleanup дерева FlowInstance после native back.
        case instance
    }
}

private enum DelegateDispatchOrder {
    case registration
    case instanceFirst
    case applicationFirst
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
