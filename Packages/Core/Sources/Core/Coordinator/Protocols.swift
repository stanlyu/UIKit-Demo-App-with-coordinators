//
//  Protocols.swift
//  Core
//
//  Created by Любченко Станислав Валерьевич on 12.02.2026.
//

import UIKit
import ObjectiveC

// Ключ для привязки жизненного цикла контейнера к UIViewController через associated object.
nonisolated(unsafe) var containerRetainKey: UInt8 = 0

// MARK: - Containing

/// Интерфейс объекта, который оборачивает UI-контент (UIViewController)
/// и управляет его жизненным циклом. Контейнеры реализуют его, чтобы оставаться чистыми Swift-объектами.
@MainActor
public protocol Containing: AnyObject {
    /// Возвращает реальный `UIViewController`, которым управляет этот контейнер.
    /// При первом вызове этого метода контейнер привязывает свой жизненный цикл к возвращаемому контроллеру.
    func extractContent() -> UIViewController
}

private final class LifecycleRetainer {
    var retainers: [ObjectIdentifier: AnyObject] = [:]
}

public extension Containing {
    func bindLifecycle(to viewController: UIViewController) {
        let retainer: LifecycleRetainer
        if let existing = objc_getAssociatedObject(viewController, &containerRetainKey) as? LifecycleRetainer {
            retainer = existing
        } else {
            retainer = LifecycleRetainer()
            objc_setAssociatedObject(viewController, &containerRetainKey, retainer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        retainer.retainers[ObjectIdentifier(self)] = self
    }
    
    func unbindLifecycle(from viewController: UIViewController) {
        if let retainer = objc_getAssociatedObject(viewController, &containerRetainKey) as? LifecycleRetainer {
            retainer.retainers.removeValue(forKey: ObjectIdentifier(self))
        }
    }
}

// MARK: - Coordinating

/// Интерфейс объекта, способного управлять навигационным потоком.
@MainActor
public protocol Coordinating: AnyObject {
    associatedtype R: Routing
    func start(with router: R)
}

// MARK: - Routing (Base)

/// Базовый протокол для всех роутеров (контейнеров).
@MainActor
public protocol Routing: Containing {
    func present(_ item: ContainerItem, animated: Bool, completion: (() -> Void)?)
    func dismiss(animated: Bool, completion: (() -> Void)?)
}

public extension Routing {
    func present(_ item: ContainerItem, animated: Bool, completion: (() -> Void)?) {
        extractContent().present(item.viewController, animated: animated, completion: completion)
    }

    func dismiss(animated: Bool, completion: (() -> Void)?) {
        extractContent().dismiss(animated: animated, completion: completion)
    }
}

// MARK: - Stack Routing

/// Возможности навигации в стеке (UINavigationController).
@MainActor
public protocol StackRouting: Routing {
    var items: [ContainerItem] { get }
    func push(_ item: ContainerItem, animated: Bool, completion: (() -> Void)?)
    func pop(animated: Bool, completion: (() -> Void)?)
    func popToRoot(animated: Bool, completion: (() -> Void)?)
    func popTo(_ item: ContainerItem, animated: Bool, completion: (() -> Void)?)
    func setStack(_ items: [ContainerItem], animated: Bool)
}

// MARK: - Switch Routing

/// Возможности контейнера, который переключает один активный контент на другой.
@MainActor
public protocol SwitchRouting: Routing {
    func setRoot(_ item: ContainerItem, animated: Bool, completion: (() -> Void)?)
}

// MARK: - Tab Routing

/// Возможности управления вкладками (UITabBarController).
@MainActor
public protocol TabRouting: Routing {
    var selectedIndex: Int { get }
    var selectedItem: ContainerItem? { get }
    func setItems(_ items: [ContainerItem], animated: Bool)
    func selectTab(at index: Int)
    func selectItem(_ item: ContainerItem)
}
