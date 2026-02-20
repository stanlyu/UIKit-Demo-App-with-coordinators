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
public protocol Routing: UIViewController {}

// MARK: - Stack Routing

/// Возможности навигации в стеке (UINavigationController).
@MainActor
public protocol StackRouting: Routing {
    /// Текущее состояние стека контроллеров в зоне ответственности роутера.
    var viewControllers: [UIViewController] { get }

    /// Кладет viewController в навигационный стек (Push).
    func push(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?)

    /// Возвращается на один экран назад (Pop).
    func pop(animated: Bool, completion: (() -> Void)?)

    /// Возвращается к корню текущего флоу (Pop To Root).
    func popToRoot(animated: Bool, completion: (() -> Void)?)

    /// Возвращается к конкретному viewController'у в стеке.
    func popTo(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?)

    /// Заменяет текущий стек на новый массив контроллеров.
    func setStack(_ viewControllers: [UIViewController], animated: Bool)
}

// MARK: - Window Routing

/// Возможности смены корневого экрана приложения (например, Splash -> Auth -> Main).
@MainActor
public protocol WindowRouting: Routing {

    /// Полностью заменяет корневой viewController с анимацией (обычно Cross Dissolve).
    /// Используется для переключения глобальных состояний приложения.
    func setRoot(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?)
}

// MARK: - Tab Routing

/// Возможности управления вкладками (UITabBarController).
@MainActor
public protocol TabRouting: Routing {

    /// Индекс текущей выбранной вкладки.
    var selectedIndex: Int { get }

    /// Текущий выбранный viewController (корневой контроллер вкладки).
    var selectedViewController: UIViewController? { get }

    /// Устанавливает контроллеры для вкладок.
    func setViewControllers(_ viewControllers: [UIViewController], animated: Bool)

    /// Переключает вкладку по индексу.
    func selectTab(at index: Int)

    /// Переключает вкладку, соответствующую переданному viewController.
    func selectViewController(_ viewController: UIViewController)
}
