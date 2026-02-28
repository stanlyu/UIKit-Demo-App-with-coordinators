//
//  StackContainer.swift
//  Core
//
//  Created by Любченко Станислав Валерьевич on 12.02.2026.
//

import UIKit

/// Контейнер, который **владеет** навигационным стеком (`UINavigationController`).
///
/// Используется для создания независимых навигационных цепочек (например, каждая вкладка таббара,
/// или модальный сценарий со своим навигационным баром).
public final class StackContainer: UINavigationController {

    /// Инициализирует контейнер с заданным координатором.
    /// - Parameter coordinator: Координатор, который будет управлять этим контейнером.
    public init(coordinator: BaseCoordinator<StackContainer>) {
        self.startFlow = { container in
            coordinator.start(with: container)
        }
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        // Автоматический запуск логики при загрузке View.
        startFlow(self)
    }

    // MARK: - Private members

    private let startFlow: (StackContainer) -> Void
}

extension StackContainer: StackRouting {
    /// Текущее состояние стека элементов в зоне ответственности контейнера.
    public var items: [ContainerItem] {
        viewControllers.map(ContainerItem.init)
    }

    /// Кладет элемент в навигационный стек.
    ///
    /// - Note: **Особенность поведения:** Если навигационный стек пуст (то есть устанавливается корневой контроллер),
    ///   параметр `animated` будет проигнорирован (принудительно `false`).
    ///   Это сделано для предотвращения визуальных глитчей при первичном появлении навигационного контроллера.
    public func push(_ item: ContainerItem, animated: Bool, completion: (() -> Void)?) {
        if viewControllers.isEmpty {
            pushViewController(item.viewController, animated: false, completion: completion)
        } else {
            pushViewController(item.viewController, animated: animated, completion: completion)
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

    /// Возвращается к указанному элементу в стеке.
    public func popTo(_ item: ContainerItem, animated: Bool, completion: (() -> Void)?) {
        popToViewController(item.viewController, animated: animated, completion: completion)
    }

    /// Заменяет весь стек на указанный массив элементов.
    public func setStack(_ items: [ContainerItem], animated: Bool) {
        setViewControllers(items.map(\.viewController), animated: animated)
    }
}
