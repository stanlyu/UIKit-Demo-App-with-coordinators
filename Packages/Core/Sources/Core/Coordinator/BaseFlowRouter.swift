import UIKit

@MainActor
internal class BaseFlowRouter<RootViewController: UIViewController> {
    internal init(rootViewController: RootViewController? = nil) {
        if let rootViewController {
            setRootViewController(rootViewController)
        }
    }

    internal var rootViewController: RootViewController? {
        weakRootViewController ?? rootViewControllerRetainer
    }

    internal func setRootViewController(_ viewController: RootViewController) {
        weakRootViewController = viewController

        if isWaitingForRuntimeAttach {
            rootViewControllerRetainer = viewController
        }
    }

    internal func releaseRootRetainer() {
        rootViewControllerRetainer = nil
        isWaitingForRuntimeAttach = false
    }

    internal func setRuntime(_ runtime: any FlowRuntimeNode) {
        self.runtime = runtime
    }

    internal func viewController(for item: RouterItem) -> UIViewController {
        if let itemRuntime = item.runtime {
            runtime?.adopt(itemRuntime)
        }
        return item.viewController
    }

    internal func viewControllers(for items: [RouterItem]) -> [UIViewController] {
        items.map { viewController(for: $0) }
    }

    private weak var weakRootViewController: RootViewController?
    private var rootViewControllerRetainer: RootViewController?
    internal weak var runtime: (any FlowRuntimeNode)?
    // Отличает состояние "root еще не установлен" от "runtime уже прикреплен".
    private var isWaitingForRuntimeAttach = true
}

extension BaseFlowRouter: FlowRuntimeRouter {}
