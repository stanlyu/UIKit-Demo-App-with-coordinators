import UIKit

/// Расширение `UINavigationController` с вариантами навигации, поддерживающими
/// обработчик завершения (`completion`).
///
/// Системные методы вызывают `completion` только по завершении анимации. Эти
/// перегрузки дополнительно вызывают его и без анимации, поэтому внешний код
/// может единообразно реагировать на конец операции.
public extension UINavigationController {

    // MARK: - Push

    /// Помещает контроллер на вершину стека и вызывает `completion` по
    /// завершении операции.
    func pushViewController(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        pushViewController(viewController, animated: animated)
        handleCompletion(animated: animated, completion: completion)
    }

    // MARK: - Pop

    /// Снимает контроллер с вершины стека и вызывает `completion` по завершении
    /// операции. Возвращает снятый контроллер.
    @discardableResult
    func popViewController(animated: Bool, completion: (() -> Void)?) -> UIViewController? {
        let poppedViewController = popViewController(animated: animated)
        handleCompletion(animated: animated, completion: completion)
        return poppedViewController
    }

    /// Снимает контроллеры до заданного включительно и вызывает `completion` по
    /// завершении операции. Возвращает список снятых контроллеров.
    @discardableResult
    func popToViewController(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?) -> [UIViewController]? {
        let poppedViewControllers = popToViewController(viewController, animated: animated)
        handleCompletion(animated: animated, completion: completion)
        return poppedViewControllers
    }

    /// Снимает все контроллеры, кроме корневого, и вызывает `completion` по
    /// завершении операции. Возвращает список снятых контроллеров.
    @discardableResult
    func popToRootViewController(animated: Bool, completion: (() -> Void)?) -> [UIViewController]? {
        let poppedViewControllers = popToRootViewController(animated: animated)
        handleCompletion(animated: animated, completion: completion)
        return poppedViewControllers
    }

    // MARK: - Set View Controllers

    /// Полностью заменяет стек контроллеров и вызывает `completion` по завершении
    /// операции.
    func setViewControllers(_ viewControllers: [UIViewController], animated: Bool, completion: (() -> Void)?) {
        setViewControllers(viewControllers, animated: animated)
        handleCompletion(animated: animated, completion: completion)
    }

    // MARK: - Private Helper

    private func handleCompletion(animated: Bool, completion: (() -> Void)?) {
        guard let completion = completion else { return }

        if animated, let coordinator = transitionCoordinator {
            coordinator.animate(alongsideTransition: nil) { context in
                // Вызываем completion в любом случае для сброса транзакции / завершения операции
                completion()
            }
        } else {
            // Если анимации нет или координатор недоступен — выполняем сразу.
            completion()
        }
    }
}
