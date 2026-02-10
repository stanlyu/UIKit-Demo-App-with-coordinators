//
//  UINavigationController.swift
//  Core
//
//  Created by Любченко Станислав Валерьевич on 10.02.2026.
//


import UIKit

public extension UINavigationController {

    // MARK: - Push

    public func pushViewController(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        pushViewController(viewController, animated: animated)
        handleCompletion(animated: animated, completion: completion)
    }

    // MARK: - Pop

    @discardableResult
    public func popViewController(animated: Bool, completion: (() -> Void)?) -> UIViewController? {
        let poppedViewController = popViewController(animated: animated)
        handleCompletion(animated: animated, completion: completion)
        return poppedViewController
    }

    @discardableResult
    public func popToViewController(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?) -> [UIViewController]? {
        let poppedViewControllers = popToViewController(viewController, animated: animated)
        handleCompletion(animated: animated, completion: completion)
        return poppedViewControllers
    }

    @discardableResult
    public func popToRootViewController(animated: Bool, completion: (() -> Void)?) -> [UIViewController]? {
        let poppedViewControllers = popToRootViewController(animated: animated)
        handleCompletion(animated: animated, completion: completion)
        return poppedViewControllers
    }

    // MARK: - Set View Controllers

    public func setViewControllers(_ viewControllers: [UIViewController], animated: Bool, completion: (() -> Void)?) {
        setViewControllers(viewControllers, animated: animated)
        handleCompletion(animated: animated, completion: completion)
    }

    // MARK: - Private Helper

    private func handleCompletion(animated: Bool, completion: (() -> Void)?) {
        guard let completion = completion else { return }

        if animated, let coordinator = transitionCoordinator {
            coordinator.animate(alongsideTransition: nil) { context in
                // Вызываем completion только если переход действительно завершился,
                // а не был отменен (например, прерванный свайп назад).
                if !context.isCancelled {
                    completion()
                }
            }
        } else {
            // Если анимации нет или координатор недоступен — выполняем сразу.
            completion()
        }
    }
}
