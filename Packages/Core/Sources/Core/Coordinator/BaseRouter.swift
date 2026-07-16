import UIKit

@MainActor
protocol FlowLifecycleRouter: AnyObject {
    func extractParentViewController() -> UIViewController?
    func setNodesManager(_ nodesManager: any FlowNodesManaging)
}

/// Базовый роутер: хранит родительский контроллер и список дочерних
/// навигационных элементов, синхронизирует дерево flow-узлов и обрабатывает
/// закрытие модальных экранов.
@MainActor
class BaseRouter<Parent: UIViewController>: NSObject, UIAdaptivePresentationControllerDelegate {
    // MARK: -  API для наследников

    /// Родительский контроллер, которым управляет роутер.
    var parentViewController: Parent {
        guard let parent = _parentViewController else {
            fatalError("Родительский view controller типа \(Parent.self) не настроен или был освобождён")
        }
        return parent
    }

    /// Навигационный элемент, оборачивающий родительский контроллер.
    var parentRouterItem: RouterItem? {
        _parentViewController.map { RouterItem($0) }
    }
    
    /// Устанавливает родительский контроллер и привязывает к нему узел координатора.
    func updateParent(_ item: RouterItem?) {
        let vc = item?.viewController as? Parent
        _parentViewController = vc
        if let vc {
            _temporaryStrongParentViewController = vc
            nodesManager?.attach(to: vc)
        }
    }

    /// Обновляет список дочерних элементов и синхронизирует дочерние узлы.
    func updateChildren(_ items: [RouterItem]) {
        self.childRouterItems = items
        nodesManager?.updateChildViewControllers(items.map(\.viewController))
    }

    // MARK: - UIAdaptivePresentationControllerDelegate

    /// При закрытии модального экрана удаляет его узел из дерева flow-узлов.
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

/// Фабрика конкретных роутеров (`stack`, `tab`, `inline`, `switch`).
@MainActor
enum RouterProvider {}
