import UIKit
import ObjectiveC

/// Хранилище связей между `UIViewController` и `FlowNode`.
///
/// Связь нужна для управления владением: узел живёт столько же, сколько его
/// корневой экран, а родительский роутер может найти дочерний узел без
/// публичного lifecycle-API.
@MainActor
protocol FlowInstanceAttachmentStoring {
    /// Удерживает объект (`retainer`) от контроллера экрана, продлевая его жизнь
    /// до времени жизни самого экрана.
    func retain(_ retainer: AnyObject, to viewController: UIViewController)

    /// Освобождает ранее удержанный объект от контроллера экрана.
    func release(_ retainer: AnyObject, from viewController: UIViewController)

    /// Хранит связь `UIViewController -> FlowNode`. Родительские роутеры
    /// используют её, чтобы усыновить дочерний flow без публичного lifecycle-API.
    func attach(_ instance: FlowNode, to viewController: UIViewController)

    /// Разрывает связь узла с контроллером экрана.
    func detach(_ instance: FlowNode, from viewController: UIViewController)

    /// Возвращает первый привязанный узел (поиск в порядке добавления).
    func instance(attachedTo viewController: UIViewController) -> FlowNode?

    /// Полный список узлов, привязанных к контроллеру, в порядке добавления.
    func instances(attachedTo viewController: UIViewController) -> [FlowNode]
}

@MainActor
enum FlowInstanceAttachments {
    /// Хранилище по умолчанию (на associated objects `UIViewController`).
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

        // Чистим мёртвые записи: после освобождения узла слабая ссылка
        // обнуляется, и запись с ней нужно убрать из словаря и порядка.
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
