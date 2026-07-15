import UIKit
import ObjectiveC

/// Хранилище связей между `UIViewController` и `FlowNode`.
///
/// Связь нужна Core для ownership: node живет столько же, сколько root
/// экран, а родительский router может найти child node без публичного
/// lifecycle API.
@MainActor
protocol FlowInstanceAttachmentStoring {
    /// Координатор/узел удерживается от root `UIViewController`, чтобы жить столько же,
    /// сколько живет экран UIKit.
    func retain(_ retainer: AnyObject, to viewController: UIViewController)
    func release(_ retainer: AnyObject, from viewController: UIViewController)

    /// Хранит связь `UIViewController -> FlowNode`.
    /// Родительские роутеры используют ее, чтобы усыновить child flow без публичного lifecycle API.
    func attach(_ instance: FlowNode, to viewController: UIViewController)
    func detach(_ instance: FlowNode, from viewController: UIViewController)
    
    /// Поиск для adoption в порядке child-first.
    func instance(attachedTo viewController: UIViewController) -> FlowNode?
    
    /// Полный список.
    func instances(attachedTo viewController: UIViewController) -> [FlowNode]
}

@MainActor
enum FlowInstanceAttachments {
    static let `default`: any FlowInstanceAttachmentStoring = AssociatedObjectFlowInstanceAttachmentStore()
}

private nonisolated(unsafe) var flowInstanceAttachmentStoreKey: UInt8 = 0

private final class FlowInstanceAssociatedStorage {
    var retainedObjects: [ObjectIdentifier: AnyObject] = [:]
    var attachedInstances: [ObjectIdentifier: WeakAttachedFlowNode] = [:]
    var instanceOrder: [ObjectIdentifier] = []
}

private typealias WeakAttachedFlowNode = WeakContainer<FlowNode, Void>


/// Реализация attachment store через associated objects на `UIViewController`.
@MainActor
final class AssociatedObjectFlowInstanceAttachmentStore: FlowInstanceAttachmentStoring {
    init() {}

    func retain(_ retainer: AnyObject, to viewController: UIViewController) {
        let storage: FlowInstanceAssociatedStorage
        if let existing = objc_getAssociatedObject(
            viewController,
            &flowInstanceAttachmentStoreKey
        ) as? FlowInstanceAssociatedStorage {
            storage = existing
        } else {
            storage = FlowInstanceAssociatedStorage()
            objc_setAssociatedObject(
                viewController,
                &flowInstanceAttachmentStoreKey,
                storage,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
        storage.retainedObjects[ObjectIdentifier(retainer)] = retainer
    }

    func release(_ retainer: AnyObject, from viewController: UIViewController) {
        if let storage = objc_getAssociatedObject(
            viewController,
            &flowInstanceAttachmentStoreKey
        ) as? FlowInstanceAssociatedStorage {
            storage.retainedObjects.removeValue(forKey: ObjectIdentifier(retainer))
        }
    }

    func attach(_ instance: FlowNode, to viewController: UIViewController) {
        let storage = storage(for: viewController)
        let instanceID = ObjectIdentifier(instance)
        if storage.attachedInstances[instanceID] == nil {
            storage.instanceOrder.append(instanceID)
        }
        storage.attachedInstances[instanceID] = WeakAttachedFlowNode(instance)
        retain(instance, to: viewController)
        if let coordinator = instance.coordinator {
            retain(coordinator, to: viewController)
        }
    }

    func detach(_ instance: FlowNode, from viewController: UIViewController) {
        if let storage = objc_getAssociatedObject(
            viewController,
            &flowInstanceAttachmentStoreKey
        ) as? FlowInstanceAssociatedStorage {
            let instanceID = ObjectIdentifier(instance)
            storage.attachedInstances.removeValue(forKey: instanceID)
            storage.instanceOrder.removeAll { $0 == instanceID }
        }
        release(instance, from: viewController)
        if let coordinator = instance.coordinator {
            release(coordinator, from: viewController)
        }
    }

    func instance(attachedTo viewController: UIViewController) -> FlowNode? {
        instances(attachedTo: viewController).first
    }

    func instances(attachedTo viewController: UIViewController) -> [FlowNode] {
        guard let storage = objc_getAssociatedObject(
            viewController,
            &flowInstanceAttachmentStoreKey
        ) as? FlowInstanceAssociatedStorage else {
            return []
        }
        
        // Решаем проблему [P2].2: очистка мертвых записей из словаря
        let deadIDs = storage.attachedInstances.filter { $0.value.object == nil }.keys
        for id in deadIDs {
            storage.attachedInstances.removeValue(forKey: id)
            storage.instanceOrder.removeAll { $0 == id }
        }
        
        return storage.instanceOrder.compactMap { storage.attachedInstances[$0]?.object }
    }

    private func storage(for viewController: UIViewController) -> FlowInstanceAssociatedStorage {
        if let existing = objc_getAssociatedObject(
            viewController,
            &flowInstanceAttachmentStoreKey
        ) as? FlowInstanceAssociatedStorage {
            return existing
        }

        let storage = FlowInstanceAssociatedStorage()
        objc_setAssociatedObject(
            viewController,
            &flowInstanceAttachmentStoreKey,
            storage,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        return storage
    }
}
