import UIKit

@MainActor
class BaseRouter<Parent: UIViewController>: NSObject, BaseNavigation, UIAdaptivePresentationControllerDelegate {
    private weak var _parentViewController: UIViewController?
    private var _temporaryStrongParentViewController: UIViewController?
    private(set) var childRouterItems: [RouterItem] = []

    var parentRouterItem: RouterItem? {
        _parentViewController.map { RouterItem($0) }
    }

    private(set) var nodesManager: (any FlowNodesManaging)?

    var parentViewController: Parent? {
        _parentViewController as? Parent
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
        let vc = item?.viewController
        _parentViewController = vc
        if let vc {
            _temporaryStrongParentViewController = vc
            Task { @MainActor in
                self._temporaryStrongParentViewController = nil
            }
            nodesManager?.attach(to: vc)
        }
    }

    func updateChildren(_ items: [RouterItem]) {
        self.childRouterItems = items
        nodesManager?.updateChildViewControllers(items.map(\.viewController))
    }

    // BaseNavigation (present/dismiss) с поддержкой поиска презентующего контроллера
    func present(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        guard let root = parentViewController else { return }
        
        item.viewController.presentationController?.delegate = self
        
        root.present(item.viewController, animated: animated, completion: completion)
    }

    func dismiss(animated: Bool, completion: (() -> Void)?) {
        guard let root = parentViewController else { return }
        root.dismiss(animated: animated, completion: completion)
    }

    // MARK: - UIAdaptivePresentationControllerDelegate

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        let dismissedVC = presentationController.presentedViewController
        if let dismissedNode = FlowInstanceAttachments.default.instance(attachedTo: dismissedVC) as? FlowNode {
            dismissedNode.parent?.removeChild(dismissedNode)
        }
    }
}
