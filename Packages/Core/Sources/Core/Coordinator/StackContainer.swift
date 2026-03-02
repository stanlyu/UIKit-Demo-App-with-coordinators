//
//  StackContainer.swift
//  Core
//
//  Created by Любченко Станислав Валерьевич on 12.02.2026.
//

import UIKit

import ObjectiveC

/// Контейнер, управляющий стеком контроллеров (UINavigationController).
@MainActor
public final class StackContainer: StackRouting {
    private weak var navigationController: UINavigationController!
    private let coordinator: any Coordinating

    public init<C: Coordinating>(coordinator: C, navigationController: UINavigationController = UINavigationController()) where C.R == StackContainer {
        self.navigationController = navigationController
        self.coordinator = coordinator
        
        self.bindLifecycle(to: navigationController)
        coordinator.start(with: self)
    }

    /// Извлекает корневой `UINavigationController`, которым управляет стек.
    ///
    /// - Returns: `UIViewController` кастованый как корневой навигационный контроллер.
    public func extractContent() -> UIViewController {
        guard let nav = navigationController else {
            fatalError("StackContainer's navigation controller was deallocated or not set.")
        }
        return nav
    }

    public var items: [ContainerItem] {
        navigationController.viewControllers.map(ContainerItem.init) ?? []
    }

    /// Осуществляет переход к новому экрану с добавлением в стек.
    ///
    /// - Parameters:
    ///   - item: `ContainerItem`, который содержит новый экран.
    ///   - animated: Использовать ли переходы при добавлении контента.
    ///   - completion: Замыкание, вызываемое после окончания перехода.
    public func push(_ item: ContainerItem, animated: Bool, completion: (() -> Void)?) {
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
    public func popTo(_ item: ContainerItem, animated: Bool, completion: (() -> Void)?) {
        navigationController.popToViewController(item.viewController, animated: animated, completion: completion)
    }

    /// Заменяет полностью массив текущего навигационного стека новым массивом экранов.
    ///
    /// - Parameters:
    ///   - items: Массив экранов, которые должны стать новым стеком `navigationController`.
    ///   - animated: Использовать ли UI-анимации для переустановки экранов.
    public func setStack(_ items: [ContainerItem], animated: Bool) {
        navigationController.setViewControllers(items.map(\.viewController), animated: animated)
    }
}
