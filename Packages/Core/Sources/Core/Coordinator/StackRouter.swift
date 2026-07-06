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
public final class StackRouter {
    /// Инициализирует роутер для управления стеком навигации.
    ///
    /// - Parameters:
    ///   - coordinator: Координатор, который будет управлять данным роутером.
    ///   - navigationController: Корневой `UINavigationController`. По умолчанию создается новый.
    ///   - lifecycleManager: Менеджер жизненного цикла. По умолчанию используется реализация через ассоциированные объекты.
    @MainActor
    public init(
        coordinator: _BaseCoordinator<StackRouter>, 
        navigationController: UINavigationController = UINavigationController(),
        lifecycleManager: any LifecycleManaging = AssociatedObjectLifecycleManager()
    ) {
        self.coordinator = coordinator
        self.navigationController = navigationController
        self.unextractedRoot = navigationController
        self.lifecycleManager = lifecycleManager
    }

    // MARK: - Private members

    private let coordinator: _BaseCoordinator<StackRouter>
    private weak var navigationController: UINavigationController?
    private var unextractedRoot: UINavigationController?
    private let lifecycleManager: any LifecycleManaging
}

// MARK: - RoutingContext

extension StackRouter: RoutingContext {

    /// Непрозрачная обертка для корневого `UIViewController`, которым управляет этот роутер.
    public var root: RouterRoot { 
        guard let navigationController = navigationController ?? unextractedRoot else {
            fatalError("StackRouter's navigation controller was deallocated or not set.")
        }
        return RouterRoot(navigationController)
    }

    /// Извлекает корневой `UINavigationController`, которым управляет стек.
    ///
    /// - Returns: `UIViewController` кастованый как корневой навигационный контроллер.
    public func extractRootUI() -> UIViewController {
        coordinator.start(with: self)
        
        guard let nav = navigationController ?? unextractedRoot else {
            fatalError("StackRouter's navigation controller was deallocated or not set.")
        }
        lifecycleManager.retain(self, to: nav)
        unextractedRoot = nil
        return nav
    }
}

// MARK: - StackRouting

extension StackRouter: StackRouting {
    /// Текущие элементы (экраны) в навигационном стеке.
    public var items: [RouterItem] {
        guard let navigationController = navigationController ?? unextractedRoot else {
            fatalError("StackRouter's navigation controller was deallocated or not set.")
        }
        return navigationController.viewControllers.map(RouterItem.init)
    }

    /// Осуществляет переход к новому экрану с добавлением в стек.
    ///
    /// - Parameters:
    ///   - item: `RouterItem`, который содержит новый экран.
    ///   - animated: Использовать ли переходы при добавлении контента.
    ///   - completion: Замыкание, вызываемое после окончания перехода.
    public func push(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        guard let navigationController = navigationController ?? unextractedRoot else {
            fatalError("StackRouter's navigation controller was deallocated or not set.")
        }

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
        guard let navigationController = navigationController ?? unextractedRoot else {
            fatalError("StackRouter's navigation controller was deallocated or not set.")
        }
        navigationController.popViewController(animated: animated, completion: completion)
    }

    /// Возвращает навигацию до корневого контроллера, сбрасывая все промежуточные экраны стека.
    ///
    /// - Parameters:
    ///   - animated: Следует ли анимировать возврат к корню.
    ///   - completion: Замыкание по завершению процесса сброса экрана стека.
    public func popToRoot(animated: Bool, completion: (() -> Void)?) {
        guard let navigationController = navigationController ?? unextractedRoot else {
            fatalError("StackRouter's navigation controller was deallocated or not set.")
        }
        navigationController.popToRootViewController(animated: animated, completion: completion)
    }

    /// Возвращает навигацию на определенный контроллер внутри стека, если этот контроллер найден.
    ///
    /// - Parameters:
    ///   - item: Объект вью контроллера, до которого нужно вернуться.
    ///   - animated: Анимировать ли процесс до целевого роутера.
    ///   - completion: Вызов завершения.
    public func popTo(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        guard let navigationController = navigationController ?? unextractedRoot else {
            fatalError("StackRouter's navigation controller was deallocated or not set.")
        }
        navigationController.popToViewController(item.viewController, animated: animated, completion: completion)
    }

    /// Заменяет полностью массив текущего навигационного стека новым массивом экранов.
    ///
    /// - Parameters:
    ///   - items: Массив экранов, которые должны стать новым стеком `navigationController`.
    ///   - animated: Использовать ли UI-анимации для переустановки экранов.
    public func setStack(_ items: [RouterItem], animated: Bool) {
        guard let navigationController = navigationController ?? unextractedRoot else {
            fatalError("StackRouter's navigation controller was deallocated or not set.")
        }
        navigationController.setViewControllers(items.map(\.viewController), animated: animated)
    }
}
