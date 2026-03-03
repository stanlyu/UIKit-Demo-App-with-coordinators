//
//  Protocols.swift
//  Core
//
//  Created by Любченко Станислав Валерьевич on 12.02.2026.
//

import UIKit
import ObjectiveC

// MARK: - RoutingContext

/// Интерфейс объекта, который оборачивает UI-контент (UIViewController)
/// и управляет его жизненным циклом. Роутеры реализуют его, чтобы оставаться чистыми Swift-объектами.
@MainActor
public protocol RoutingContext: AnyObject {
    /// Возвращает реальный `UIViewController`, которым управляет этот роутер.
    /// При первом вызове этого метода роутер привязывает свой жизненный цикл к возвращаемому контроллеру.
    func extractRootUI() -> UIViewController
}

// MARK: - Coordinating

/// Интерфейс объекта, способного управлять навигационным потоком.
@MainActor
public protocol Coordinating: AnyObject {
    associatedtype R: Routing
    func start(with router: R)
}

// MARK: - Routing (Base)

/// Базовый протокол для всех роутеров (роутеров).
@MainActor
public protocol Routing: RoutingContext {
    func present(_ item: RouterItem, animated: Bool, completion: (() -> Void)?)
    func dismiss(animated: Bool, completion: (() -> Void)?)
}

public extension Routing {
    func present(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        extractRootUI().present(item.viewController, animated: animated, completion: completion)
    }

    func dismiss(animated: Bool, completion: (() -> Void)?) {
        extractRootUI().dismiss(animated: animated, completion: completion)
    }
}

// MARK: - Stack Routing

/// Возможности навигации в стеке (UINavigationController).
@MainActor
public protocol StackRouting: Routing {
    var items: [RouterItem] { get }
    func push(_ item: RouterItem, animated: Bool, completion: (() -> Void)?)
    func pop(animated: Bool, completion: (() -> Void)?)
    func popToRoot(animated: Bool, completion: (() -> Void)?)
    func popTo(_ item: RouterItem, animated: Bool, completion: (() -> Void)?)
    func setStack(_ items: [RouterItem], animated: Bool)
}

// MARK: - Switch Routing

/// Возможности роутера, который переключает один активный контент на другой.
@MainActor
public protocol SwitchRouting: Routing {
    func setRoot(_ item: RouterItem, animated: Bool, completion: (() -> Void)?)
}

// MARK: - Tab Routing

/// Возможности управления вкладками (UITabBarController).
@MainActor
public protocol TabRouting: Routing {
    var selectedIndex: Int { get }
    var selectedItem: RouterItem? { get }
    func setItems(_ items: [RouterItem], animated: Bool)
    func selectTab(at index: Int)
    func selectItem(_ item: RouterItem)
}
