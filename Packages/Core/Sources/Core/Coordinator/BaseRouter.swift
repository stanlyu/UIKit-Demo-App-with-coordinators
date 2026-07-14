import UIKit

@MainActor
open class BaseRouter: NSObject, BaseNavigation, UIAdaptivePresentationControllerDelegate {
    private(set) var parentRouterItem: RouterItem?
    private(set) var childRouterItems: [RouterItem] = []

    private(set) var nodesManager: (any FlowNodesManaging)?

    func setNodesManager(_ nodesManager: any FlowNodesManaging) {
        self.nodesManager = nodesManager
    }

    // API для наследников
    func updateParent(_ item: RouterItem?) {
        self.parentRouterItem = item
        nodesManager?.updateParentViewController(item?.viewController)
    }

    func updateChildren(_ items: [RouterItem]) {
        self.childRouterItems = items
        nodesManager?.updateChildViewControllers(items.map(\.viewController))
    }

    // BaseNavigation (present/dismiss) с поддержкой поиска презентующего контроллера
    open func present(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        guard let root = parentRouterItem?.viewController ?? childRouterItems.first?.viewController else { return }
        
        // Решаем проблему [P1].4 свайпа вниз модального контроллера
        item.viewController.presentationController?.delegate = self
        
        root.present(item.viewController, animated: animated, completion: completion)
    }

    open func dismiss(animated: Bool, completion: (() -> Void)?) {
        guard let root = parentRouterItem?.viewController ?? childRouterItems.first?.viewController else { return }
        root.dismiss(animated: animated, completion: completion)
    }

    // MARK: - UIAdaptivePresentationControllerDelegate

    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        let dismissedVC = presentationController.presentedViewController
        if let dismissedNode = FlowInstanceAttachments.default.instance(attachedTo: dismissedVC) as? FlowNode {
            dismissedNode.parent?.removeChild(dismissedNode)
        }
    }
}
