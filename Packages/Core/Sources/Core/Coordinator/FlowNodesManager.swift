import UIKit

@MainActor
internal final class FlowNodesManager: FlowNodesManaging {
    internal let node: FlowNode
    private let attachmentStore: any FlowInstanceAttachmentStoring
    private weak var rootViewController: UIViewController?

    internal init(
        coordinator: AnyObject,
        attachmentStore: any FlowInstanceAttachmentStoring = FlowInstanceAttachments.default
    ) {
        self.node = FlowNode(coordinator: coordinator)
        self.attachmentStore = attachmentStore
    }

    internal func setRootViewController(_ viewController: UIViewController) {
        self.rootViewController = viewController
        attachmentStore.attach(node, to: viewController)
    }

    internal func updateParentViewController(_ parentVC: UIViewController?) {
        guard let parentVC, let parentNode = attachmentStore.instance(attachedTo: parentVC) as? FlowNode else {
            node.setParent(nil)
            return
        }
        parentNode.adopt(node)
    }

    internal func updateChildViewControllers(_ childVCs: [UIViewController]) {
        // Находим все дочерние ноды, привязанные к переданным контроллерам
        let activeChildNodes = childVCs.compactMap { vc in
            attachmentStore.instance(attachedTo: vc) as? FlowNode
        }

        // Усыновляем новые ноды
        for childNode in activeChildNodes {
            if childNode !== node {
                node.adopt(childNode)
            }
        }

        // Удаляем ноды, которых больше нет в стеке
        let currentChildren = node.children
        for child in currentChildren {
            if !activeChildNodes.contains(where: { $0 === child }) {
                node.removeChild(child)
            }
        }
    }
}
