//
//  Protocols.swift
//  Core
//
//  Created by Любченко Станислав Валерьевич on 12.02.2026.
//

import UIKit

// MARK: - Routing (Base)

/// Базовый протокол для всех роутеров (контейнеров).
@MainActor
public protocol Routing: UIViewController {
    func present(_ item: ContainerItem, animated: Bool, completion: (() -> Void)?)
}

public extension Routing {
    func present(_ item: ContainerItem, animated: Bool, completion: (() -> Void)?) {
        present(item.viewController, animated: animated, completion: completion)
    }
}

// MARK: - Stack Routing

/// Возможности навигации в стеке (UINavigationController).
@MainActor
public protocol StackRouting: Routing {
    /// Текущее состояние стека элементов в зоне ответственности роутера.
    var items: [ContainerItem] { get }

    /// Кладет элемент в навигационный стек (Push).
    func push(_ item: ContainerItem, animated: Bool, completion: (() -> Void)?)

    /// Возвращается на один экран назад (Pop).
    func pop(animated: Bool, completion: (() -> Void)?)

    /// Возвращается к корню текущего флоу (Pop To Root).
    func popToRoot(animated: Bool, completion: (() -> Void)?)

    /// Возвращается к конкретному элементу в стеке.
    func popTo(_ item: ContainerItem, animated: Bool, completion: (() -> Void)?)

    /// Заменяет текущий стек на новый массив элементов.
    func setStack(_ items: [ContainerItem], animated: Bool)
}

// MARK: - Switch Routing

/// Возможности контейнера, который переключает один активный контент на другой.
///
/// Типичный кейс: смена корневого сценария приложения (например, Splash -> Main),
/// но протокол не привязан только к `UIWindow`.
@MainActor
public protocol SwitchRouting: Routing {

    /// Полностью заменяет текущий контент контейнера новым элементом.
    /// При использовании в root-сценарии это эквивалентно смене корневого экрана.
    func setRoot(_ item: ContainerItem, animated: Bool, completion: (() -> Void)?)
}

// MARK: - Tab Routing

/// Возможности управления вкладками (UITabBarController).
@MainActor
public protocol TabRouting: Routing {

    /// Индекс текущей выбранной вкладки.
    var selectedIndex: Int { get }

    /// Текущий выбранный элемент вкладки.
    var selectedItem: ContainerItem? { get }

    /// Устанавливает элементы для вкладок.
    func setItems(_ items: [ContainerItem], animated: Bool)

    /// Переключает вкладку по индексу.
    func selectTab(at index: Int)

    /// Переключает вкладку, соответствующую переданному элементу.
    func selectItem(_ item: ContainerItem)
}
