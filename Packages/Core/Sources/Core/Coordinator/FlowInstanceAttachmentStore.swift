//
//  FlowInstanceAttachmentStore.swift
//  Core
//

import UIKit
import ObjectiveC

/// Хранилище связей между `UIViewController` и `FlowInstance`.
///
/// Связь нужна Core для ownership: instance живет столько же, сколько root
/// экран, а родительский router может найти child instance без публичного
/// lifecycle API.
@MainActor
internal protocol FlowInstanceAttachmentStoring {
    /// `FlowInstance` удерживается от root `UIViewController`, чтобы жить столько же,
    /// сколько живет экран UIKit.
    func retain(_ retainer: AnyObject, to viewController: UIViewController)
    func release(_ retainer: AnyObject, from viewController: UIViewController)

    /// Хранит связь `UIViewController -> FlowInstanceNode`.
    /// Родительские роутеры используют ее, чтобы усыновить child flow без публичного lifecycle API.
    func attach(_ instance: any FlowInstanceNode, to viewController: UIViewController)
    func detach(_ instance: any FlowInstanceNode, from viewController: UIViewController)
    /// Поиск для adoption в порядке child-first: если `UIViewController` является root child flow,
    /// родительский router должен сначала увидеть именно этот child instance.
    func instance(attachedTo viewController: UIViewController) -> (any FlowInstanceNode)?
    /// Полный список нужен для removal: удалять можно только direct child текущего `FlowInstance`,
    /// а не первый instance на `UIViewController`.
    func instances(attachedTo viewController: UIViewController) -> [any FlowInstanceNode]
}

@MainActor
internal enum FlowInstanceAttachments {
    internal static let `default`: any FlowInstanceAttachmentStoring = AssociatedObjectFlowInstanceAttachmentStore()
}

private nonisolated(unsafe) var flowInstanceAttachmentStoreKey: UInt8 = 0

private final class FlowInstanceAssociatedStorage {
    var retainedObjects: [ObjectIdentifier: AnyObject] = [:]
    var attachedInstances: [ObjectIdentifier: WeakAttachedFlowInstanceNode] = [:]
    var instanceOrder: [ObjectIdentifier] = []
}

private final class WeakAttachedFlowInstanceNode {
    init(_ instance: any FlowInstanceNode) {
        self.instance = instance
    }

    weak var instance: (any FlowInstanceNode)?
}

/// Реализация attachment store через associated objects на `UIViewController`.
@MainActor
internal final class AssociatedObjectFlowInstanceAttachmentStore: FlowInstanceAttachmentStoring {
    internal init() {}

    internal func retain(_ retainer: AnyObject, to viewController: UIViewController) {
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

    internal func release(_ retainer: AnyObject, from viewController: UIViewController) {
        if let storage = objc_getAssociatedObject(
            viewController,
            &flowInstanceAttachmentStoreKey
        ) as? FlowInstanceAssociatedStorage {
            storage.retainedObjects.removeValue(forKey: ObjectIdentifier(retainer))
        }
    }

    internal func attach(_ instance: any FlowInstanceNode, to viewController: UIViewController) {
        let storage = storage(for: viewController)
        let instanceID = ObjectIdentifier(instance)
        if storage.attachedInstances[instanceID] == nil {
            storage.instanceOrder.append(instanceID)
        }
        storage.attachedInstances[instanceID] = WeakAttachedFlowInstanceNode(instance)
        retain(instance, to: viewController)
    }

    internal func detach(_ instance: any FlowInstanceNode, from viewController: UIViewController) {
        if let storage = objc_getAssociatedObject(
            viewController,
            &flowInstanceAttachmentStoreKey
        ) as? FlowInstanceAssociatedStorage {
            let instanceID = ObjectIdentifier(instance)
            storage.attachedInstances.removeValue(forKey: instanceID)
            storage.instanceOrder.removeAll { $0 == instanceID }
        }
        release(instance, from: viewController)
    }

    internal func instance(attachedTo viewController: UIViewController) -> (any FlowInstanceNode)? {
        instances(attachedTo: viewController).first
    }

    internal func instances(attachedTo viewController: UIViewController) -> [any FlowInstanceNode] {
        guard let storage = objc_getAssociatedObject(
            viewController,
            &flowInstanceAttachmentStoreKey
        ) as? FlowInstanceAssociatedStorage else {
            return []
        }
        storage.instanceOrder.removeAll { storage.attachedInstances[$0]?.instance == nil }
        return storage.instanceOrder.compactMap { storage.attachedInstances[$0]?.instance }
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
