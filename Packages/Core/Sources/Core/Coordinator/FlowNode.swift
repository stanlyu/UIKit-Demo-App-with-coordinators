import UIKit

@MainActor
public final class FlowNode: AnyObject {
    public private(set) weak var coordinator: AnyObject?
    public private(set) weak var parent: FlowNode?
    public private(set) var children: [FlowNode] = []

    public init(coordinator: AnyObject) {
        self.coordinator = coordinator
    }

    func setParent(_ parent: FlowNode?) {
        self.parent = parent
    }

    func adopt(_ child: FlowNode) {
        if child === self { return }
        child.parent?.removeChild(child)
        children.append(child)
        child.setParent(self)
    }

    func removeChild(_ child: FlowNode) {
        children.removeAll { $0 === child }
        if child.parent === self {
            child.setParent(nil)
        }
    }
}
