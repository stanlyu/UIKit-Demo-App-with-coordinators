import UIKit

@MainActor
internal final class FlowRuntime<RootViewController, Router, Navigation, Route, Coordinator>
where
    RootViewController: UIViewController,
    Router: BaseFlowRouter<RootViewController>,
    Coordinator: BaseCoordinator<Navigation, Route>
{
    internal init(
        router: Router,
        coordinator: Coordinator,
        lifecycleManager: any LifecycleManaging = AssociatedObjectLifecycleManager()
    ) {
        self.router = router
        self.coordinator = coordinator
        self.lifecycleManager = lifecycleManager
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

        lifecycleManager.retain(self, to: newRoot)

        if let attachedRoot {
            lifecycleManager.release(self, from: attachedRoot)
        }

        attachedRoot = newRoot
    }

    private let router: Router
    private let coordinator: Coordinator
    private let lifecycleManager: any LifecycleManaging
    private weak var attachedRoot: UIViewController?
}
