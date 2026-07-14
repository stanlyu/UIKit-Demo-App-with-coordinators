import UIKit

/// Общая UIKit-реализация modal presentation/dismiss.
///
/// Driver возвращает `NavigationMutation`, чтобы `FlowRouter` синхронизировал
/// дерево `FlowInstance` после завершения UIKit-перехода.
@MainActor
internal enum FlowPresentationDriver {
    internal static func present(
        _ viewController: UIViewController,
        from presenter: UIViewController,
        item: RouterItem,
        animated: Bool,
        completion: @escaping (NavigationMutation) -> Void
    ) {
        presenter.present(viewController, animated: animated) {
            completion(NavigationMutation(insertedItems: [item]))
        }
    }

    internal static func dismissPresentedContent(
        from presenter: UIViewController,
        animated: Bool,
        completion: @escaping (NavigationMutation) -> Void
    ) {
        let removedViewControllers = presentedViewControllerChain(from: presenter)
        presenter.dismiss(animated: animated) {
            completion(NavigationMutation(removedViewControllers: removedViewControllers))
        }
    }

    internal static func requireRoot<RootViewController: UIViewController>(
        _ rootViewController: RootViewController?,
        message: @autoclosure () -> String
    ) -> RootViewController {
        guard let rootViewController else {
            fatalError(message())
        }
        return rootViewController
    }

    private static func presentedViewControllerChain(from presenter: UIViewController) -> [UIViewController] {
        var viewControllers: [UIViewController] = []
        var currentViewController = presenter.presentedViewController

        while let viewController = currentViewController {
            viewControllers.append(viewController)
            currentViewController = viewController.presentedViewController
        }

        return viewControllers
    }
}
