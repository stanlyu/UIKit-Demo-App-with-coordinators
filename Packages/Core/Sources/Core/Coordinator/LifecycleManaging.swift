//
//  LifecycleManaging.swift
//  Core
//

import UIKit
import ObjectiveC

@MainActor
public protocol LifecycleManaging {
    /// Привязывает время жизни переданного объекта (retainer) к времени жизни переданного экрана (viewController).
    /// Когда viewController деаллоцируется, retainer тоже освобождается.
    func retain(_ retainer: AnyObject, to viewController: UIViewController)
    
    /// Явно отвязывает объект от экрана.
    func release(_ retainer: AnyObject, from viewController: UIViewController)
}

private nonisolated(unsafe) var routerRetainKey: UInt8 = 0

/// Контейнер для словаря объектов, который будет привязан к UIViewController
private final class LifecycleAssociatedStorage {
    var retainedObjects: [ObjectIdentifier: AnyObject] = [:]
}

@MainActor
public final class AssociatedObjectLifecycleManager: LifecycleManaging {
    public init() {}
    
    public func retain(_ retainer: AnyObject, to viewController: UIViewController) {
        let storage: LifecycleAssociatedStorage
        if let existing = objc_getAssociatedObject(viewController, &routerRetainKey) as? LifecycleAssociatedStorage {
            storage = existing
        } else {
            storage = LifecycleAssociatedStorage()
            objc_setAssociatedObject(viewController, &routerRetainKey, storage, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        storage.retainedObjects[ObjectIdentifier(retainer)] = retainer
    }
    
    public func release(_ retainer: AnyObject, from viewController: UIViewController) {
        if let storage = objc_getAssociatedObject(viewController, &routerRetainKey) as? LifecycleAssociatedStorage {
            storage.retainedObjects.removeValue(forKey: ObjectIdentifier(retainer))
        }
    }
}
