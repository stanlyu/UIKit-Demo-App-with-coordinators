//
//  StackRouter.swift
//  Core
//
//  Created by Любченко Станислав Валерьевич on 12.02.2026.
//

import UIKit

import ObjectiveC

/// Роутер, управляющий стеком контроллеров (UINavigationController).
@MainActor
public final class StackRouter: StackRouting {
    public init<C: Coordinating>(
        coordinator: C, 
        navigationController: UINavigationController = UINavigationController(),
        lifecycleManager: any LifecycleManaging = AssociatedObjectLifecycleManager()
    ) where C.R == StackRouter {
        self.navigationController = navigationController
        self.lifecycleManager = lifecycleManager
        self._startCoordinator = { router in
            coordinator.start(with: router)
        }
        
        self.lifecycleManager.retain(self, to: navigationController)
    }

    /// Извлекает корневой `UINavigationController`, которым управляет стек.
    ///
    /// - Returns: `UIViewController` кастованый как корневой навигационный контроллер.
    public func extractRootUI() -> UIViewController {
        _startCoordinator?(self)
        _startCoordinator = nil
        
        guard let nav = navigationController else {
            fatalError("StackRouter's navigation controller was deallocated or not set.")
        }
        return nav
    }

    public var items: [RouterItem] {
        navigationController.viewControllers.map(RouterItem.init) ?? []
    }

    /// Осуществляет переход к новому экрану с добавлением в стек.
    ///
    /// - Parameters:
    ///   - item: `RouterItem`, который содержит новый экран.
    ///   - animated: Использовать ли переходы при добавлении контента.
    ///   - completion: Замыкание, вызываемое после окончания перехода.
    public func push(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        if navigationController.viewControllers.isEmpty {
            navigationController.pushViewController(item.viewController, animated: false, completion: completion)
        } else {
            navigationController.pushViewController(item.viewController, animated: animated, completion: completion)
        }
    }

    /// Возвращает навигацию на один уровень назад.
    ///
    /// - Parameters:
    ///   - animated: Следует ли анимировать возвращение назад.
    ///   - completion: Вызывается по окончанию перехода на предыдущий контроллер.
    public func pop(animated: Bool, completion: (() -> Void)?) {
        navigationController.popViewController(animated: animated, completion: completion)
    }

    /// Возвращает навигацию до корневого контроллера, сбрасывая все промежуточные экраны стека.
    ///
    /// - Parameters:
    ///   - animated: Следует ли анимировать возврат к корню.
    ///   - completion: Замыкание по завершению процесса сброса экрана стека.
    public func popToRoot(animated: Bool, completion: (() -> Void)?) {
        navigationController.popToRootViewController(animated: animated, completion: completion)
    }

    /// Возвращает навигацию на определенный контроллер внутри стека, если этот контроллер найден.
    ///
    /// - Parameters:
    ///   - item: Объект вью контроллера, до которого нужно вернуться.
    ///   - animated: Анимировать ли процесс до целевого роутера.
    ///   - completion: Вызов завершения.
    public func popTo(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        navigationController.popToViewController(item.viewController, animated: animated, completion: completion)
    }

    /// Заменяет полностью массив текущего навигационного стека новым массивом экранов.
    ///
    /// - Parameters:
    ///   - items: Массив экранов, которые должны стать новым стеком `navigationController`.
    ///   - animated: Использовать ли UI-анимации для переустановки экранов.
    public func setStack(_ items: [RouterItem], animated: Bool) {
        navigationController.setViewControllers(items.map(\.viewController), animated: animated)
    }

    // MARK: - Private members

    private weak var navigationController: UINavigationController!
    private let lifecycleManager: any LifecycleManaging
    private var _startCoordinator: ((StackRouter) -> Void)?
}
