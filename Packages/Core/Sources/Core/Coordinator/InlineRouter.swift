//
//  InlineRouter.swift
//  Core
//
//  Created by Любченко Станислав Валерьевич on 12.02.2026.
//

import UIKit


/// Роутер, который **встраивается** в существующий навигационный стек.
///
/// Является `ProxyViewController`, то есть для системы выглядит как один экран,
/// но на самом деле управляет сегментом стека родительского навигационного контроллера.
///
/// - Note: **Конфигурация:** Этот роутер прозрачен. Если вам нужно настроить заголовок флоу,
///   скрыть таббар (`hidesBottomBarWhenPushed`) или изменить кнопки навигации,
///   настраивайте эти свойства у **первого контроллера** (Root of Flow), который вы передаете в этот роутер.
///   Настройка самого `InlineRouter` бесполезна, так как он зеркалирует свой контент.
public final class InlineRouter: ProxyViewController {

    /// Инициализирует роутер с заданным координатором.
    /// - Parameter coordinator: Координатор, который будет управлять этим роутером.
    public init(coordinator: Coordinator<InlineRouter>) {
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
        // Запускаем поток сразу, чтобы Proxy получил контент и синхронизировал
        // системные флаги (hidesBottomBar, navigationItem) до того,
        // как этот контроллер попадет в стек навигации.
        coordinator.start(with: self)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private members

    private let coordinator: Coordinator<InlineRouter>
}

extension InlineRouter: StackRouting {
    /// Текущий стек контроллеров внутри флоу InlineRouter.
    ///
    /// - Note: В качестве первого элемента возвращается `contentViewController`,
    ///   а не сам `InlineRouter`, чтобы координатор работал с реальными экранами своего флоу.
    public var viewControllers: [UIViewController] {
        guard let contentViewController else { return [] }
        guard let navigationController else { return [contentViewController] }
        guard let selfIndex = navigationController.viewControllers.firstIndex(of: self) else { return [contentViewController] }

        let flowStack = Array(navigationController.viewControllers[selfIndex...])
        return [contentViewController] + flowStack.dropFirst()
    }

    /// Добавляет viewController во флоу.
    ///
    /// - Note: **Особенность поведения:**
    ///   1. Если это **первый** viewController во флоу, он будет встроен внутрь самого `InlineRouter` (через `setContent`).
    ///      Визуально переход не произойдет, так как `InlineRouter` уже находится в стеке.
    ///   2. Если это **второй и последующие** viewControllers, они будут стандартно запушены (`push`)
    ///      в навигационный стек родительского контейнера.
    public func push(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        if contentViewController == nil {
            setContent(viewController)
            completion?()
        } else {
            guard let nav = navigationController else {
                assertionFailure("⚠️ InlineRouter: Попытка push, но роутер не находится в NavigationController.")
                return
            }
            nav.pushViewController(viewController, animated: animated, completion: completion)
        }
    }

    /// Возвращается на один экран назад.
    ///
    /// - Warning: **Ошибка логики:** Запрещено вызывать этот метод, если `InlineRouter` является верхним контроллером в стеке
    ///   (то есть вы пытаетесь закрыть сам флоу изнутри). В Debug-сборке это вызовет `assertionFailure`.
    ///   Для закрытия всего флоу используйте делегирование к родительскому координатору.
    public func pop(animated: Bool, completion: (() -> Void)?) {
        guard let nav = navigationController else {
            assertionFailure("⚠️ InlineRouter: Попытка pop, но роутер не находится в NavigationController.")
            return
        }

        if nav.topViewController === self {
            let message = """
            ⚠️ ОШИБКА ЛОГИКИ InlineRouter:
            Вы пытаетесь вызвать pop() для корневого контроллера этого флоу.
            InlineRouter не может удалить сам себя из стека родителя.
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
    /// - Note: Этот метод вернет стек к состоянию, когда `InlineRouter` находится на вершине.
    public func popToRoot(animated: Bool, completion: (() -> Void)?) {
        popTo(self, animated: animated, completion: completion)
    }

    /// Возвращается к указанному viewController'у.
    ///
    /// - Warning: **Ошибка логики:** Целевой viewController должен находиться в пределах "зоны ответственности" этого роутера.
    ///   Попытка перейти к контроллеру, который находится в стеке **до** `InlineRouter` (экраны родителя),
    ///   вызовет `assertionFailure` в Debug-сборке.
    public func popTo(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        guard let nav = navigationController else {
            "⚠️ InlineRouter: Попытка popTo, но роутер не находится в NavigationController."
            return
        }

        let stack = nav.viewControllers

        guard let selfIndex = stack.firstIndex(of: self),
              let targetIndex = stack.firstIndex(of: viewController) else { return }

        if targetIndex < selfIndex {
            let message = """
            ⚠️ ОШИБКА ЛОГИКИ InlineRouter:
            Попытка перехода (popTo) к контроллеру, который находится ВНЕ зоны ответственности этого роутера.
            Вы пытаетесь вернуться к экрану родительского координатора.
            РЕШЕНИЕ: Используйте делегирование для управления родительским потоком.
            """
            assertionFailure(message)
            return
        }

        nav.popToViewController(viewController, animated: animated, completion: completion)
    }

    /// Заменяет текущий стек флоу на новые viewControllers.
    ///
    /// - Note: Этот метод сохраняет все контроллеры в стеке **до** `InlineRouter` (родительские экраны),
    ///   обновляет контент самого `InlineRouter` первым viewController из массива,
    ///   и добавляет остальные viewControllers поверх него.
    public func setStack(_ viewControllers: [UIViewController], animated: Bool) {
        guard let first = viewControllers.first else { return }

        setContent(first)

        guard let nav = navigationController else {
            "⚠️ InlineRouter: Попытка setStack, но роутер не находится в NavigationController."
            return
        }

        var currentStack = nav.viewControllers

        if let selfIndex = currentStack.firstIndex(of: self) {
            currentStack = Array(currentStack.prefix(upTo: selfIndex + 1))
        }

        if viewControllers.count > 1 {
            currentStack.append(contentsOf: viewControllers.dropFirst())
        }

        nav.setViewControllers(currentStack, animated: animated)
    }
}
