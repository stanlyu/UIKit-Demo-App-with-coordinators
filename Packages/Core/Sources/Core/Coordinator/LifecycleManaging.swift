//
//  LifecycleManaging.swift
//  Core
//

import UIKit
import ObjectiveC

/// Менеджер, отвечающий за привязку жизненного цикла роутеров к жизненному циклу `UIViewController`.
///
/// Роутеры (например, `StackRouter`, `TabRouter`) используют этот сервис, 
/// чтобы не удаляться из памяти до тех пор, пока жив соответствующий экран UIKit.
@MainActor
public protocol LifecycleManaging {
    /// Привязывает время жизни переданного объекта (retainer) к времени жизни переданного экрана (viewController).
    /// Когда viewController деаллоцируется, retainer тоже освобождается.
    func retain(_ retainer: AnyObject, to viewController: UIViewController)
    
    /// Явно отвязывает объект от экрана.
    func release(_ retainer: AnyObject, from viewController: UIViewController)
}

@MainActor
internal protocol FlowAttachmentManaging: LifecycleManaging {
    func attach(_ runtime: any FlowRuntimeNode, to viewController: UIViewController)
    func detach(_ runtime: any FlowRuntimeNode, from viewController: UIViewController)
    func runtime(attachedTo viewController: UIViewController) -> (any FlowRuntimeNode)?
}

@MainActor
internal enum FlowAttachmentManager {
    internal static let `default`: any FlowAttachmentManaging = AssociatedObjectLifecycleManager()
}

private nonisolated(unsafe) var routerRetainKey: UInt8 = 0

// Контейнер для словаря объектов, который будет привязан к UIViewController
private final class LifecycleAssociatedStorage {
    var retainedObjects: [ObjectIdentifier: AnyObject] = [:]
    weak var attachedRuntime: (any FlowRuntimeNode)?
}

/// Имплементация `LifecycleManaging`, которая использует `Associated Objects` из Objective-C Runtime
/// для удержания сильных ссылок на роутеры.
@MainActor
public final class AssociatedObjectLifecycleManager: FlowAttachmentManaging {
    /// Инициализирует менеджер.
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

    internal func attach(_ runtime: any FlowRuntimeNode, to viewController: UIViewController) {
        let storage = storage(for: viewController)
        storage.attachedRuntime = runtime
        retain(runtime, to: viewController)
    }

    internal func detach(_ runtime: any FlowRuntimeNode, from viewController: UIViewController) {
        if let storage = objc_getAssociatedObject(viewController, &routerRetainKey) as? LifecycleAssociatedStorage,
           storage.attachedRuntime === runtime {
            storage.attachedRuntime = nil
        }
        release(runtime, from: viewController)
    }

    internal func runtime(attachedTo viewController: UIViewController) -> (any FlowRuntimeNode)? {
        guard let storage = objc_getAssociatedObject(viewController, &routerRetainKey) as? LifecycleAssociatedStorage else {
            return nil
        }
        return storage.attachedRuntime
    }

    private func storage(for viewController: UIViewController) -> LifecycleAssociatedStorage {
        if let existing = objc_getAssociatedObject(viewController, &routerRetainKey) as? LifecycleAssociatedStorage {
            return existing
        }

        let storage = LifecycleAssociatedStorage()
        objc_setAssociatedObject(viewController, &routerRetainKey, storage, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return storage
    }
}
