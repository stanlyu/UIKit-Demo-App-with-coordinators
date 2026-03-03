//
//  InlineRouter.swift
//  Core
//
//  Created by Любченко Станислав Валерьевич on 12.02.2026.
//

import UIKit
import ObjectiveC

/// Роутер, который **встраивается** в существующий навигационный стек.
@MainActor
public final class InlineRouter {
    /// Текущий отображаемый контроллер, вставленный инлайном в чужой `UINavigationController`.
    public private(set) weak var contentViewController: UIViewController?

    /// Инициализирует инлайн-роутер.
    ///
    /// - Parameters:
    ///   - coordinator: Координатор, который будет управлять данным роутером.
    ///   - lifecycleManager: Менеджер жизненного цикла. По умолчанию используется реализация через ассоциированные объекты.
    @MainActor
    public init(
        coordinator: _BaseCoordinator<InlineRouter>,
        lifecycleManager: any LifecycleManaging = AssociatedObjectLifecycleManager()
    ) {
        self.coordinator = coordinator
        self.lifecycleManager = lifecycleManager
    }

    private func setContent(_ content: UIViewController) {
        if let current = contentViewController {
            lifecycleManager.release(self, from: current)
        }
        self.contentViewController = content
        self.unextractedContent = content // Сохраняем сильную ссылку до момента вызова extractRootUI
        lifecycleManager.retain(self, to: content)
    }

    // MARK: - Private members

    private let coordinator: _BaseCoordinator<InlineRouter>
    private var unextractedContent: UIViewController?
    private let lifecycleManager: any LifecycleManaging
    
}

// MARK: - RoutingContext

extension InlineRouter: RoutingContext {
    /// Непрозрачная обертка для корневого `UIViewController`, которым управляет этот роутер.
    public var root: RouterRoot {
        guard let content = contentViewController ?? unextractedContent else {
            fatalError("InlineRouter has no content when accessing root.")
        }
        return RouterRoot(content)
    }

    /// Извлекает корневой `UIViewController` из роутера.
    ///
    /// Этот метод должен быть вызван один раз, чтобы получить `UIViewController`,
    /// который затем может быть встроен в `UINavigationController` или другой роутер.
    /// После вызова `extractRootUI()` роутер больше не будет удерживать сильную ссылку на этот контроллер.
    ///
    /// - Returns: Корневой `UIViewController` этого инлайн-флоу.
    /// - Precondition: Метод `setContent` должен быть вызван хотя бы один раз до вызова `extractRootUI()`.
    public func extractRootUI() -> UIViewController {
        coordinator.start(with: self)
        
        guard let content = contentViewController ?? unextractedContent else {
            fatalError("InlineRouter's extractRootUI() called but no content was provided by the coordinator.")
        }
        unextractedContent = nil
        return content
    }
}

// MARK: - Displaying (StackRouting)

extension InlineRouter: StackRouting {
    /// Текущие элементы (экраны) в инлайн-последовательности навигационного стека (начиная от корневого инлайн-элемента).
    public var items: [RouterItem] {
        guard let contentViewController else { return [] }
        guard let navigationController = contentViewController.navigationController else { return [RouterItem(contentViewController)] }
        guard let selfIndex = navigationController.viewControllers.firstIndex(of: contentViewController) else {
            return [RouterItem(contentViewController)]
        }

        let flowStack = Array(navigationController.viewControllers[selfIndex...])
        // Возвращаем сам contentViewController плюс все что лежит поверх него
        return flowStack.map(RouterItem.init)
    }

    public func push(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        if contentViewController == nil {
            setContent(item.viewController)
            completion?()
        } else {
            guard let nav = contentViewController?.navigationController else {
                assertionFailure("⚠️ InlineRouter: Попытка push, но контент не находится в NavigationController.")
                return
            }
            nav.pushViewController(item.viewController, animated: animated, completion: completion)
        }
    }

    public func pop(animated: Bool, completion: (() -> Void)?) {
        guard let nav = contentViewController?.navigationController, let content = contentViewController else {
            assertionFailure("⚠️ InlineRouter: Попытка pop, но контент не находится в NavigationController.")
            return
        }

        if nav.topViewController === content {
            let message = """
            ⚠️ ОШИБКА ЛОГИКИ InlineRouter:
            Вы пытаетесь вызвать pop() для корневого контроллера этого флоу.
            """
            assertionFailure(message)
            return
        }

        nav.popViewController(animated: animated, completion: completion)
    }

    public func popToRoot(animated: Bool, completion: (() -> Void)?) {
        if let content = contentViewController {
            popTo(RouterItem(content), animated: animated, completion: completion)
        }
    }

    public func popTo(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        guard let nav = contentViewController?.navigationController, let content = contentViewController else {
            assertionFailure("⚠️ InlineRouter: Попытка popTo, но контент не находится в NavigationController.")
            return
        }

        let stack = nav.viewControllers

        guard let selfIndex = stack.firstIndex(of: content), 
              let targetIndex = stack.firstIndex(of: item.viewController) else { return }

        if targetIndex < selfIndex {
            assertionFailure("⚠️ ОШИБКА ЛОГИКИ InlineRouter: Попытка перехода вне зоны ответственности.")
            return
        }

        nav.popToViewController(item.viewController, animated: animated, completion: completion)
    }

    public func setStack(_ items: [RouterItem], animated: Bool) {
        guard let first = items.first else { return }

        if contentViewController == nil {
            setContent(first.viewController)
        }
        
        guard let nav = contentViewController?.navigationController, let content = contentViewController else {
            assertionFailure("⚠️ InlineRouter: Попытка setStack, но контент не находится в NavigationController.")
            return
        }

        var currentStack = nav.viewControllers

        if let selfIndex = currentStack.firstIndex(of: content) {
            currentStack = Array(currentStack.prefix(upTo: selfIndex + 1))
        }

        if items.count > 1 {
            currentStack.append(contentsOf: items.dropFirst().map(\.viewController))
        }

        nav.setViewControllers(currentStack, animated: animated)
    }
}
