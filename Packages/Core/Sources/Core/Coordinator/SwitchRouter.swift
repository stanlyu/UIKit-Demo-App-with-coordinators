import UIKit

/// Кастомный обработчик перехода при замене корневого экрана.
///
/// Возвращает `true`, если переход выполнен обработчиком самостоятельно (тогда
/// стандартная логика `SwitchRouter` не применяется), иначе `false`.
typealias SwitchTransitionHandler = @MainActor @Sendable (
    _ oldViewController: UIViewController,
    _ newViewController: UIViewController,
    _ animated: Bool,
    _ completion: @escaping @MainActor @Sendable () -> Void
) -> Bool

extension RouterProvider {
    /// Создаёт роутер, где одновременно активен только один корневой экран,
    /// целиком заменяемый при переключении.
    static func `switch`() -> SwitchNavigation & FlowLifecycleRouter {
        SwitchRouter()
    }
}

// Роутер переключаемого контента: заменяет текущий корневой экран новым в
// рамках navigation controller, tab bar controller или окна.
@MainActor
private final class SwitchRouter: BaseRouter<UIViewController> {
    // Текущий корневой контроллер, если он задан.
    var rootViewController: UIViewController? {
        parentRouterItem?.viewController
    }

    // Удерживает прежний корневой контроллер до завершения перехода, чтобы
    // избежать его преждевременного освобождения во время анимации.
    var oldContentRetainer: UIViewController?
    // Необязательный кастомный обработчик перехода.
    var transitionHandler: SwitchTransitionHandler?

    // Устанавливает кастомный обработчик перехода; `nil` отключает его.
    func setTransitionHandler(_ handler: SwitchTransitionHandler?) {
        self.transitionHandler = handler
    }

    func performTransition(
        from oldVC: UIViewController,
        to newVC: UIViewController,
        animated: Bool,
        completion: @escaping @MainActor @Sendable () -> Void
    ) {
        if transitionHandler?(oldVC, newVC, animated, completion) == true {
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

    func transitionInWindow(
        _ window: UIWindow,
        to newVC: UIViewController,
        animated: Bool,
        completion: @escaping @MainActor @Sendable () -> Void
    ) {
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

extension SwitchRouter: SwitchNavigation {
    var currentItem: RouterItem? {
        parentRouterItem
    }
    
    func switchTo(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        let newVC = item.viewController
        guard let oldVC = rootViewController else {
            updateParent(item)
            completion?()
            return
        }

        updateParent(item)
        oldContentRetainer = oldVC

        performTransition(from: oldVC, to: newVC, animated: animated) { [weak self] in
            guard let self else { return }
            if self.oldContentRetainer === oldVC {
                self.oldContentRetainer = nil
            }
            completion?()
        }
    }
}
