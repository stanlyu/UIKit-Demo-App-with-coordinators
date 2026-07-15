import UIKit

@MainActor
protocol FlowLifecycleRouter: AnyObject {
    func extractParentViewController() -> UIViewController?
    func setNodesManager(_ nodesManager: any FlowNodesManaging)
}

@MainActor
class BaseRouter<Parent: UIViewController>: NSObject, BaseNavigation, UIAdaptivePresentationControllerDelegate, FlowLifecycleRouter {
    private weak var _parentViewController: Parent?
    private var _temporaryStrongParentViewController: Parent?
    private(set) var childRouterItems: [RouterItem] = []

    private(set) var nodesManager: (any FlowNodesManaging)?

    var parent: Parent {
        guard let parent = _parentViewController as? Parent else {
            fatalError("Parent view controller of type \(Parent.self) is not configured or has been deallocated")
        }
        return parent
    }

    var subclassParentRouterItem: RouterItem? {
        _parentViewController.map { RouterItem($0) }
    }

    var childViewControllers: [UIViewController] {
        childRouterItems.map(\.viewController)
    }

    func setNodesManager(_ nodesManager: any FlowNodesManaging) {
        self.nodesManager = nodesManager
        if let vc = _parentViewController {
            nodesManager.attach(to: vc)
        }
    }

    // API для наследников
    func updateParent(_ item: RouterItem?) {
        let vc = item?.viewController as? Parent
        _parentViewController = vc
        if let vc {
            _temporaryStrongParentViewController = vc
            nodesManager?.attach(to: vc)
        }
    }

    func extractParentViewController() -> UIViewController? {
        let vc = _temporaryStrongParentViewController
        _temporaryStrongParentViewController = nil
        return vc
    }

    func updateChildren(_ items: [RouterItem]) {
        self.childRouterItems = items
        nodesManager?.updateChildViewControllers(items.map(\.viewController))
    }

    // BaseNavigation (present/dismiss) с поддержкой поиска презентующего контроллера
    func present(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        let root = parent
        
        item.viewController.presentationController?.delegate = self
        
        root.present(item.viewController, animated: animated, completion: completion)
    }

    func dismiss(animated: Bool, completion: (() -> Void)?) {
        parent.dismiss(animated: animated, completion: completion)
    }

    // MARK: - UIAdaptivePresentationControllerDelegate

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        let dismissedVC = presentationController.presentedViewController
        if let dismissedNode = FlowInstanceAttachments.default.instance(attachedTo: dismissedVC) as? FlowNode {
            dismissedNode.parent?.removeChild(dismissedNode)
        }
    }
}
