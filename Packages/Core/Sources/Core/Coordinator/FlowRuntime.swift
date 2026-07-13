import UIKit

@MainActor
internal protocol FlowRuntimeNode: AnyObject {
    var parent: (any FlowRuntimeNode)? { get }
    var children: [any FlowRuntimeNode] { get }

    func adopt(_ child: any FlowRuntimeNode)
    func removeChild(_ child: any FlowRuntimeNode)
    func setParent(_ parent: (any FlowRuntimeNode)?)
}

private final class WeakFlowRuntimeNode {
    init(_ runtime: any FlowRuntimeNode) {
        self.runtime = runtime
    }

    weak var runtime: (any FlowRuntimeNode)?
}

@MainActor
internal protocol FlowRuntimeRouter: AnyObject {
    associatedtype RootViewController: UIViewController

    var rootViewController: RootViewController? { get }

    func setRuntime(_ runtime: any FlowRuntimeNode)
    func releaseRootRetainer()
}

@MainActor
internal final class FlowRuntime<RootViewController, Router, Navigation, Route, Coordinator>
where
    RootViewController: UIViewController,
    Router: FlowRuntimeRouter,
    Router.RootViewController == RootViewController,
    Coordinator: BaseCoordinator<Navigation, Route>
{
    internal init(
        router: Router,
        coordinator: Coordinator,
        attachmentManager: any FlowAttachmentManaging = FlowAttachmentManager.default
    ) {
        self.router = router
        self.coordinator = coordinator
        self.attachmentManager = attachmentManager
        router.setRuntime(self)
    }

    internal func run() -> UIViewController {
        coordinator.start(CoordinatorStartContext())

        guard let root = router.rootViewController else {
            fatalError("Coordinator must set root content during start(_:).")
        }

        attach(to: root)
        router.releaseRootRetainer()
        return root
    }

    internal func attach(to newRoot: UIViewController) {
        if attachedRoot === newRoot { return }

        attachmentManager.attach(self, to: newRoot)

        if let attachedRoot {
            attachmentManager.detach(self, from: attachedRoot)
        }

        attachedRoot = newRoot
    }

    private let router: Router
    private let coordinator: Coordinator
    private let attachmentManager: any FlowAttachmentManaging
    private weak var attachedRoot: UIViewController?
    private weak var parentRuntime: (any FlowRuntimeNode)?
    private var childRuntimes: [ObjectIdentifier: WeakFlowRuntimeNode] = [:]
}

extension FlowRuntime: FlowRuntimeNode {
    internal var parent: (any FlowRuntimeNode)? {
        parentRuntime
    }

    internal var children: [any FlowRuntimeNode] {
        childRuntimes = childRuntimes.filter { $0.value.runtime != nil }
        return childRuntimes.values.compactMap(\.runtime)
    }

    internal func adopt(_ child: any FlowRuntimeNode) {
        if child === self { return }

        child.parent?.removeChild(child)

        let childID = ObjectIdentifier(child)
        childRuntimes[childID] = WeakFlowRuntimeNode(child)
        child.setParent(self)
    }

    internal func removeChild(_ child: any FlowRuntimeNode) {
        childRuntimes.removeValue(forKey: ObjectIdentifier(child))

        if child.parent === self {
            child.setParent(nil)
        }
    }

    internal func setParent(_ parent: (any FlowRuntimeNode)?) {
        parentRuntime = parent
    }
}
