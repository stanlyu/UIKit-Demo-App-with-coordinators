import UIKit

@MainActor
final class FlowNodesManager: FlowNodesManaging {
    let node: FlowNode
    private let attachmentStore: any FlowInstanceAttachmentStoring

    init(
        coordinator: any Coordinating,
        attachmentStore: any FlowInstanceAttachmentStoring = FlowInstanceAttachments.default
    ) {
        self.node = FlowNode(coordinator: coordinator)
        self.attachmentStore = attachmentStore
    }

    func attach(to viewController: UIViewController) {
        attachmentStore.attach(node, to: viewController)
    }


    func updateChildViewControllers(_ childVCs: [UIViewController]) {
        // Находим все дочерние ноды, привязанные к переданным контроллерам
        let activeChildNodes = childVCs.compactMap { vc in
            attachmentStore.instance(attachedTo: vc)
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
