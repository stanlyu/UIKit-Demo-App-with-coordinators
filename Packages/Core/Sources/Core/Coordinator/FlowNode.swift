import UIKit

// MARK: - Intent dispatch extension point

/// Маркерный протокол для интентов (пуш, диплинк, universal link).
///
/// `CoordinatorIntent` — точка расширения для будущей диспетчеризации интентов
/// по дереву координаторов. Конкретный тип интента определяется приложением:
/// механизм координаторов намеренно ничего не знает про `URL`, удалённые
/// уведомления или deep links — он лишь задаёт общий язык, которым координаторы
/// обмениваются событиями извне.
///
/// Протокол не содержит требований: конкретная полезная нагрузка (URL,
/// идентификатор пуша, параметры диплинка) живёт в конкретных типах, которые
/// приложение реализует и передаёт в `Coordinating.receive(_:)`. Так механизм
/// координаторов не зависит от транспортного слоя.
@MainActor
public protocol CoordinatorIntent: AnyObject {}

/// Координатор, способный обрабатывать интенты в responder chain.
///
/// Дерево координаторов состоит из узлов разных типов: каждый узел хранит
/// `any Coordinating` вместо дженерик-типа, поэтому интенты распространяются без
/// статического знания о конкретном координаторе. По умолчанию координатор не
/// обрабатывает интенты (`receive(_:) -> false`); наследники переопределяют
/// метод, чтобы вернуть `true` и остановить распространение, когда интент
/// обработан.
///
/// - Note: Реализация диспетчеризации интентов по дереву намеренно отложена.
///   Протокол вводится сейчас, чтобы типизировать `FlowNode.coordinator` и
///   зафиксировать контракт для будущей работы.
@MainActor
public protocol Coordinating: AnyObject {
    /// Обработать интент.
    ///
    /// - Parameter intent: Интент, распространяемый по дереву координаторов.
    /// - Returns: `true`, если интент обработан и распространение нужно
    ///   остановить; `false`, если координатор интент не обработал.
    func receive(_ intent: any CoordinatorIntent) -> Bool
}

extension Coordinating {
    /// По умолчанию координатор не обрабатывает интенты.
    public func receive(_ intent: any CoordinatorIntent) -> Bool { false }
}

// MARK: - FlowNode

/// Узел дерева flow-инстансов.
///
/// Хранит слабую ссылку на координатор (`any Coordinating`), что позволяет
/// будущему механизму диспетчеризации интентов обращаться к координатору без
/// знания о его конкретном типе. Дочерние узлы образуют дерево отношений
/// «родитель — ребёнок», отражающее вложенность flow.
@MainActor
public final class FlowNode: AnyObject {
    /// Координатор, владеющий этим узлом. Типизирован через `any Coordinating`,
    /// чтобы будущий intent-dispatch мог вызывать `receive(_:)` на любом узле дерева.
    public private(set) weak var coordinator: (any Coordinating)?
    /// Родительский узел, либо `nil` для корня дерева.
    public private(set) weak var parent: FlowNode?
    /// Дочерние узлы в порядке добавления.
    public private(set) var children: [FlowNode] = []

    /// - Parameter coordinator: Координатор, которому принадлежит узел.
    public init(coordinator: any Coordinating) {
        self.coordinator = coordinator
    }

    func setParent(_ parent: FlowNode?) {
        self.parent = parent
    }

    /// Усыновляет дочерний узел: отвязывает его от прежнего родителя и
    /// добавляет в конец списка детей.
    func adopt(_ child: FlowNode) {
        guard child !== self else { return }
        child.parent?.removeChild(child)
        children.append(child)
        child.setParent(self)
    }

    /// Удаляет дочерний узел из списка детей и очищает его ссылку на родителя.
    func removeChild(_ child: FlowNode) {
        children.removeAll { $0 === child }
        if child.parent === self {
            child.setParent(nil)
        }
    }
}
