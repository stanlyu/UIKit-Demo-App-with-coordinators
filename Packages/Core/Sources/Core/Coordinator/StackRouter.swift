//
//  StackRouter.swift
//  Core
//
//  Created by Любченко Станислав Валерьевич on 12.02.2026.
//

import UIKit

/// Роутер, который **владеет** навигационным стеком (`UINavigationController`).
///
/// Используется для создания независимых навигационных цепочек (например, каждая вкладка таббара,
/// или модальный сценарий со своим навигационным баром).
public final class StackRouter: UINavigationController {

    /// Инициализирует роутер с заданным координатором.
    /// - Parameter coordinator: Координатор, который будет управлять этим роутером.
    public init(coordinator: Coordinator) {
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        // Автоматический запуск логики при загрузке View.
        coordinator.start()
    }

    // MARK: - Private members

    private let coordinator: Coordinator
}

extension StackRouter: StackRouting {
    /// Кладет модуль в навигационный стек.
    ///
    /// - Note: **Особенность поведения:** Если навигационный стек пуст (то есть устанавливается корневой контроллер),
    ///   параметр `animated` будет проигнорирован (принудительно `false`).
    ///   Это сделано для предотвращения визуальных глитчей при первичном появлении навигационного контроллера.
    public func push(_ module: UIViewController, animated: Bool, completion: (() -> Void)?) {
        if viewControllers.isEmpty {
            pushViewController(module, animated: false, completion: completion)
        } else {
            pushViewController(module, animated: animated, completion: completion)
        }
    }

    /// Возвращается на один экран назад.
    public func pop(animated: Bool, completion: (() -> Void)?) {
        popViewController(animated: animated, completion: completion)
    }

    /// Возвращается к первому контроллеру в стеке.
    public func popToRoot(animated: Bool, completion: (() -> Void)?) {
        popToRootViewController(animated: animated, completion: completion)
    }

    /// Возвращается к указанному модулю в стеке.
    public func popTo(_ module: UIViewController, animated: Bool, completion: (() -> Void)?) {
        popToViewController(module, animated: animated, completion: completion)
    }

    /// Заменяет весь стек на указанный массив контроллеров.
    public func setStack(_ modules: [UIViewController], animated: Bool) {
        setViewControllers(modules, animated: animated)
    }
}
