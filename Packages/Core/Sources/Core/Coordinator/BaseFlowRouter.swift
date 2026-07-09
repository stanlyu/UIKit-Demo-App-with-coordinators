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

    private weak var weakRootViewController: RootViewController?
    private var rootViewControllerRetainer: RootViewController?
    // Отличает состояние "root еще не установлен" от "runtime уже прикреплен".
    private var isWaitingForRuntimeAttach = true
}
