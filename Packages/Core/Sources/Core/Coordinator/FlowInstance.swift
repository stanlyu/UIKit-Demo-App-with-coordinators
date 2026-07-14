import UIKit

/// Узел дерева активных flow.
///
/// Core использует дерево, чтобы усыновлять child flow при navigation mutation
/// и освобождать direct child при удалении его root `UIViewController`.
@MainActor
internal protocol FlowInstanceNode: AnyObject {
    var parent: (any FlowInstanceNode)? { get }
    var children: [any FlowInstanceNode] { get }

    func adopt(_ child: any FlowInstanceNode)
    func removeChild(_ child: any FlowInstanceNode)
    func setParent(_ parent: (any FlowInstanceNode)?)
}

private final class WeakFlowInstanceNode {
    init(_ instance: any FlowInstanceNode) {
        self.instance = instance
    }

    weak var instance: (any FlowInstanceNode)?
}

/// Минимальный контракт router-а, который нужен `FlowInstance`.
@MainActor
internal protocol FlowInstanceRouter: AnyObject {
    associatedtype RootViewController: UIViewController

    var rootViewController: RootViewController? { get }
    var onRootReplaced: (@MainActor (RootViewController) -> Void)? { get set }

    func setInstance(_ instance: any FlowInstanceNode)
    func markInstanceAttachedAndReleaseBootstrapRoot()
}

/// Жизненный контейнер одного flow.
///
/// Удерживает router и coordinator, запускает coordinator и привязывает себя
/// к root `UIViewController` через attachment store.
@MainActor
internal final class FlowInstance<RootViewController, Router, Navigation, Route, Coordinator>
where
    RootViewController: UIViewController,
    Router: FlowInstanceRouter,
    Router.RootViewController == RootViewController,
    Coordinator: BaseCoordinator<Navigation, Route>
{
    internal init(
        router: Router,
        coordinator: Coordinator,
        attachmentStore: any FlowInstanceAttachmentStoring = FlowInstanceAttachments.default
    ) {
        self.router = router
        self.coordinator = coordinator
        self.attachmentStore = attachmentStore
        router.setInstance(self)
        router.onRootReplaced = { [weak self] newRoot in
            self?.attach(to: newRoot)
        }
    }

    internal func run() -> UIViewController {
        coordinator.start(CoordinatorStartContext())

        guard let root = router.rootViewController else {
            fatalError("Coordinator must set root content during start(_:).")
        }

        attach(to: root)
        router.markInstanceAttachedAndReleaseBootstrapRoot()
        return root
    }

    internal func attach(to newRoot: UIViewController) {
        if attachedRoot === newRoot { return }

        attachmentStore.attach(self, to: newRoot)

        if let attachedRoot {
            attachmentStore.detach(self, from: attachedRoot)
        }

        attachedRoot = newRoot
    }

    private let router: Router
    private let coordinator: Coordinator
    private let attachmentStore: any FlowInstanceAttachmentStoring
    private weak var attachedRoot: UIViewController?
    private weak var parentInstance: (any FlowInstanceNode)?
    private var childInstances: [ObjectIdentifier: WeakFlowInstanceNode] = [:]
}

extension FlowInstance: FlowInstanceNode {
    internal var parent: (any FlowInstanceNode)? {
        parentInstance
    }

    internal var children: [any FlowInstanceNode] {
        childInstances = childInstances.filter { $0.value.instance != nil }
        return childInstances.values.compactMap(\.instance)
    }

    internal func adopt(_ child: any FlowInstanceNode) {
        if child === self { return }

        child.parent?.removeChild(child)

        let childID = ObjectIdentifier(child)
        childInstances[childID] = WeakFlowInstanceNode(child)
        child.setParent(self)
    }

    internal func removeChild(_ child: any FlowInstanceNode) {
        childInstances.removeValue(forKey: ObjectIdentifier(child))

        if child.parent === self {
            child.setParent(nil)
        }
    }

    internal func setParent(_ parent: (any FlowInstanceNode)?) {
        parentInstance = parent
    }
}
