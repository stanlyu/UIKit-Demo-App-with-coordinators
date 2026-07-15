import UIKit

@MainActor
protocol FlowLifecycleRouter: AnyObject {
    func extractParentViewController() -> UIViewController?
    func setNodesManager(_ nodesManager: any FlowNodesManaging)
}

@MainActor
class BaseRouter<Parent: UIViewController>: NSObject, UIAdaptivePresentationControllerDelegate {
    // MARK: -  API для наследников
    
    var parentViewController: Parent {
        guard let parent = _parentViewController else {
            fatalError("Parent view controller of type \(Parent.self) is not configured or has been deallocated")
        }
        return parent
    }

    var parentRouterItem: RouterItem? {
        _parentViewController.map { RouterItem($0) }
    }
    
    func updateParent(_ item: RouterItem?) {
        let vc = item?.viewController as? Parent
        _parentViewController = vc
        if let vc {
            _temporaryStrongParentViewController = vc
            nodesManager?.attach(to: vc)
        }
    }

    func updateChildren(_ items: [RouterItem]) {
        self.childRouterItems = items
        nodesManager?.updateChildViewControllers(items.map(\.viewController))
    }
    
    // MARK: - UIAdaptivePresentationControllerDelegate
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        let dismissedVC = presentationController.presentedViewController
        if let dismissedNode = FlowInstanceAttachments.default.instance(attachedTo: dismissedVC) {
            dismissedNode.parent?.removeChild(dismissedNode)
        }
    }
    
    // MARK: - Private members
    
    private weak var _parentViewController: Parent?
    private var _temporaryStrongParentViewController: Parent?
    private(set) var childRouterItems: [RouterItem] = []
    private var nodesManager: (any FlowNodesManaging)?
}

extension BaseRouter: FlowLifecycleRouter {
    func setNodesManager(_ nodesManager: any FlowNodesManaging) {
        self.nodesManager = nodesManager
        if let vc = _parentViewController {
            nodesManager.attach(to: vc)
        }
    }
    
    func extractParentViewController() -> UIViewController? {
        let vc = _temporaryStrongParentViewController
        _temporaryStrongParentViewController = nil
        return vc
    }
}

extension BaseRouter: BaseNavigation {
    func present(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        let root = parentViewController
        
        item.viewController.presentationController?.delegate = self
        
        root.present(item.viewController, animated: animated, completion: completion)
    }

    func dismiss(animated: Bool, completion: (() -> Void)?) {
        parentViewController.dismiss(animated: animated, completion: completion)
    }
}

@MainActor 
enum RouterProvider {}
