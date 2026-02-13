//
//  Protocols.swift
//  Core
//
//  Created by Любченко Станислав Валерьевич on 12.02.2026.
//

import UIKit


// MARK: - Routing (Base)

/// Базовый протокол для всех роутеров (контейнеров).
/// Предоставляет методы для модального показа экранов.
@MainActor
public protocol Routing: UIViewController {

    /// Презентует модуль модально.
    /// - Parameters:
    ///   - module: Вью контроллер (или Роутер) для показа.
    ///   - animated: Анимировать ли появление.
    ///   - completion: Блок, вызываемый после завершения анимации.
    func present(_ module: UIViewController, animated: Bool, completion: (() -> Void)?)

    /// Закрывает текущий модуль (если он был показан модально) или закрывает показанный им модуль.
    /// - Parameters:
    ///   - animated: Анимировать ли скрытие.
    ///   - completion: Блок, вызываемый после завершения анимации.
    func dismissModule(animated: Bool, completion: (() -> Void)?)
}

// Default Implementation
extension Routing {
    public func present(_ module: UIViewController, animated: Bool, completion: (() -> Void)? = nil) {
        self.present(module, animated: animated, completion: completion)
    }

    public func dismissModule(animated: Bool, completion: (() -> Void)? = nil) {
        self.dismiss(animated: animated, completion: completion)
    }
}

// MARK: - Stack Routing

/// Возможности навигации в стеке (UINavigationController).
@MainActor
public protocol StackRouting: Routing {

    /// Кладет модуль в навигационный стек (Push).
    func push(_ module: UIViewController, animated: Bool, completion: (() -> Void)?)

    /// Возвращается на один экран назад (Pop).
    func pop(animated: Bool, completion: (() -> Void)?)

    /// Возвращается к корню текущего флоу (Pop To Root).
    func popToRoot(animated: Bool, completion: (() -> Void)?)

    /// Возвращается к конкретному модулю в стеке.
    func popTo(_ module: UIViewController, animated: Bool, completion: (() -> Void)?)

    /// Заменяет текущий стек на новый массив контроллеров.
    func setStack(_ modules: [UIViewController], animated: Bool)
}

// MARK: - Window Routing

/// Возможности смены корневого экрана приложения (например, Splash -> Auth -> Main).
@MainActor
public protocol WindowRouting: Routing {

    /// Полностью заменяет корневой модуль с анимацией (обычно Cross Dissolve).
    /// Используется для переключения глобальных состояний приложения.
    func setRoot(_ module: UIViewController, animated: Bool, completion: (() -> Void)?)
}

// MARK: - Tab Routing

/// Возможности управления вкладками (UITabBarController).
@MainActor
public protocol TabRouting: Routing {

    /// Индекс текущей выбранной вкладки.
    var selectedIndex: Int { get }

    /// Текущий выбранный модуль (корневой контроллер вкладки).
    var selectedModule: UIViewController? { get }

    /// Устанавливает контроллеры для вкладок.
    func setTabs(_ modules: [UIViewController], animated: Bool)

    /// Переключает вкладку по индексу.
    func selectTab(at index: Int)

    /// Переключает вкладку, соответствующую переданному модулю.
    func selectModule(_ module: UIViewController)
}
