import UIKit
import ObjectiveC

/// Хранилище связей между `UIViewController` и `FlowNode`.
///
/// Связь нужна для управления владением: узел живёт столько же, сколько его
/// корневой экран, а родительский роутер может найти дочерний узел без
/// публичного lifecycle-API.
@MainActor
protocol FlowInstanceAttachmentStoring {
    /// Удерживает объект от контроллера экрана, продлевая его жизнь до времени
    /// жизни самого экрана.
    ///
    /// - Parameters:
    ///   - retainer: Объект, который нужно удержать.
    ///   - viewController: Контроллер экрана, к которому привязывается удержание.
    func retain(_ retainer: AnyObject, to viewController: UIViewController)

    /// Освобождает ранее удержанный объект от контроллера экрана.
    ///
    /// - Parameters:
    ///   - retainer: Объект, удержание которого снимается.
    ///   - viewController: Контроллер экрана, от которого отвязывается удержание.
    func release(_ retainer: AnyObject, from viewController: UIViewController)

    /// Привязывает узел flow к контроллеру экрана. Родительские роутеры
    /// используют эту связь, чтобы усыновить дочерний flow без публичного
    /// lifecycle-API.
    ///
    /// - Parameters:
    ///   - instance: Узел flow, который привязывается.
    ///   - viewController: Контроллер экрана, к которому привязывается узел.
    func attach(_ instance: FlowNode, to viewController: UIViewController)

    /// Разрывает связь узла с контроллером экрана.
    ///
    /// - Parameters:
    ///   - instance: Узел flow, связь которого снимается.
    ///   - viewController: Контроллер экрана, от которого отвязывается узел.
    func detach(_ instance: FlowNode, from viewController: UIViewController)

    /// Возвращает первый привязанный к контроллеру узел в порядке добавления.
    ///
    /// - Parameter viewController: Контроллер экрана, для которого ищется узел.
    /// - Returns: Первый привязанный узел, либо `nil`, если привязок нет.
    func instance(attachedTo viewController: UIViewController) -> FlowNode?

    /// Возвращает все узлы, привязанные к контроллеру, в порядке добавления.
    ///
    /// - Parameter viewController: Контроллер экрана, для которого ищутся узлы.
    /// - Returns: Список привязанных узлов в порядке добавления (пустой, если
    ///   привязок нет).
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
        // обнуляется, и запись нужно убрать из словаря привязок и из массива
        // порядка добавления (`instanceOrder`).
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
