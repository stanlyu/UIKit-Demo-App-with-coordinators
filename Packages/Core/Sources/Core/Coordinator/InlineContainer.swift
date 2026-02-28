//
//  InlineContainer.swift
//  Core
//
//  Created by Любченко Станислав Валерьевич on 12.02.2026.
//

import UIKit

/// Контейнер, который **встраивается** в существующий навигационный стек.
///
/// Является `ProxyViewController`, то есть для системы выглядит как один экран,
/// но на самом деле управляет сегментом стека родительского навигационного контроллера.
///
/// - Note: **Конфигурация:** Этот контейнер прозрачен. Если вам нужно настроить заголовок флоу,
///   скрыть таббар (`hidesBottomBarWhenPushed`) или изменить кнопки навигации,
///   настраивайте эти свойства у **первого контроллера** (Root of Flow), который вы передаете в этот контейнер.
///   Настройка самого `InlineContainer` бесполезна, так как он зеркалирует свой контент.
public final class InlineContainer: ProxyViewController {

    /// Инициализирует контейнер с заданным координатором.
    /// - Parameter coordinator: Координатор, который будет управлять этим контейнером.
    public init(coordinator: BaseCoordinator<InlineContainer>) {
        self.startFlow = { container in
            coordinator.start(with: container)
        }
        super.init(nibName: nil, bundle: nil)
        // Запускаем поток сразу, чтобы Proxy получил контент и синхронизировал
        // системные флаги (hidesBottomBar, navigationItem) до того,
        // как этот контроллер попадет в стек навигации.
        startFlow(self)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private members

    private let startFlow: (InlineContainer) -> Void
}

extension InlineContainer: StackRouting {
    /// Текущий стек элементов внутри флоу InlineContainer.
    ///
    /// - Note: В качестве первого элемента возвращается `contentViewController`,
    ///   а не сам `InlineContainer`, чтобы координатор работал с реальными экранами своего флоу.
    public var items: [ContainerItem] {
        guard let contentViewController else { return [] }
        guard let navigationController else { return [ContainerItem(contentViewController)] }
        guard let selfIndex = navigationController.viewControllers.firstIndex(of: self) else {
            return [ContainerItem(contentViewController)]
        }

        let flowStack = Array(navigationController.viewControllers[selfIndex...])
        return [ContainerItem(contentViewController)] + flowStack.dropFirst().map(ContainerItem.init)
    }

    /// Добавляет элемент во флоу.
    ///
    /// - Note: **Особенность поведения:**
    ///   1. Если это **первый** элемент во флоу, он будет встроен внутрь самого `InlineContainer` (через `setContent`).
    ///      Визуально переход не произойдет, так как `InlineContainer` уже находится в стеке.
    ///   2. Если это **второй и последующие** элементы, они будут стандартно запушены (`push`)
    ///      в навигационный стек родительского контейнера.
    public func push(_ item: ContainerItem, animated: Bool, completion: (() -> Void)?) {
        if contentViewController == nil {
            setContent(item.viewController)
            completion?()
        } else {
            guard let nav = navigationController else {
                assertionFailure("⚠️ InlineContainer: Попытка push, но контейнер не находится в NavigationController.")
                return
            }
            nav.pushViewController(item.viewController, animated: animated, completion: completion)
        }
    }

    /// Возвращается на один экран назад.
    ///
    /// - Warning: **Ошибка логики:** Запрещено вызывать этот метод, если `InlineContainer` является верхним контроллером в стеке
    ///   (то есть вы пытаетесь закрыть сам флоу изнутри). В Debug-сборке это вызовет `assertionFailure`.
    ///   Для закрытия всего флоу используйте делегирование к родительскому координатору.
    public func pop(animated: Bool, completion: (() -> Void)?) {
        guard let nav = navigationController else {
            assertionFailure("⚠️ InlineContainer: Попытка pop, но контейнер не находится в NavigationController.")
            return
        }

        if nav.topViewController === self {
            let message = """
            ⚠️ ОШИБКА ЛОГИКИ InlineContainer:
            Вы пытаетесь вызвать pop() для корневого контроллера этого флоу.
            InlineContainer не может удалить сам себя из стека родителя.
            РЕШЕНИЕ: Координатор должен вызвать делегат (например, onFinish), а родительский координатор \
            должен сделать router.pop().
            """
            assertionFailure(message)
            return
        }

        nav.popViewController(animated: animated, completion: completion)
    }

    /// Возвращается к началу текущего флоу.
    ///
    /// - Note: Этот метод вернет стек к состоянию, когда `InlineContainer` находится на вершине.
    public func popToRoot(animated: Bool, completion: (() -> Void)?) {
        // ИСПРАВЛЕНО ЗДЕСЬ: оборачиваем self в ContainerItem
        popTo(ContainerItem(self), animated: animated, completion: completion)
    }

    /// Возвращается к указанному элементу.
    ///
    /// - Warning: **Ошибка логики:** Целевой элемент должен находиться в пределах "зоны ответственности" этого контейнера.
    ///   Попытка перейти к контроллеру, который находится в стеке **до** `InlineContainer` (экраны родителя),
    ///   вызовет `assertionFailure` в Debug-сборке.
    public func popTo(_ item: ContainerItem, animated: Bool, completion: (() -> Void)?) {
        guard let nav = navigationController else {
            assertionFailure("⚠️ InlineContainer: Попытка popTo, но контейнер не находится в NavigationController.")
            return
        }

        let stack = nav.viewControllers

        guard let selfIndex = stack.firstIndex(of: self),
              let targetIndex = stack.firstIndex(of: item.viewController) else { return }

        if targetIndex < selfIndex {
            let message = """
            ⚠️ ОШИБКА ЛОГИКИ InlineContainer:
            Попытка перехода (popTo) к контроллеру, который находится ВНЕ зоны ответственности этого контейнера.
            Вы пытаетесь вернуться к экрану родительского координатора.
            РЕШЕНИЕ: Используйте делегирование для управления родительским потоком.
            """
            assertionFailure(message)
            return
        }

        nav.popToViewController(item.viewController, animated: animated, completion: completion)
    }

    /// Заменяет текущий стек флоу на новые элементы.
    ///
    /// - Note: Этот метод сохраняет все контроллеры в стеке **до** `InlineContainer` (родительские экраны),
    ///   обновляет контент самого `InlineContainer` первым элементом из массива,
    ///   и добавляет остальные элементы поверх него.
    public func setStack(_ items: [ContainerItem], animated: Bool) {
        guard let first = items.first else { return }

        setContent(first.viewController)
        
        guard let nav = navigationController else {
            assertionFailure("⚠️ InlineContainer: Попытка setStack, но контейнер не находится в NavigationController.")
            return
        }

        var currentStack = nav.viewControllers

        if let selfIndex = currentStack.firstIndex(of: self) {
            currentStack = Array(currentStack.prefix(upTo: selfIndex + 1))
        }

        if items.count > 1 {
            currentStack.append(contentsOf: items.dropFirst().map(\.viewController))
        }

        nav.setViewControllers(currentStack, animated: animated)
    }
}
