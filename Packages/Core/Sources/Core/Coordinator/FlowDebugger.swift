import UIKit

#if DEBUG
/// Отладочный помощник: строит текстовое представление текущего дерева
/// flow-инстансов по активному окну.
public enum FlowDebugger {
    /// Возвращает текстовый дамп дерева сценариев активного окна.
    ///
    /// - Returns: Многострочное описание дерева; строка-заглушка, если активного
    ///   окна нет.
    @MainActor
    public static func dumpActiveFlowTree() -> String {
        var output = ""
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first(where: \.isKeyWindow)?.rootViewController else {
            return "No active key window"
        }
        dump(viewController: rootVC, depth: 0, output: &output)
        return output
    }

    @MainActor
    private static func dump(viewController: UIViewController, depth: Int, output: inout String) {
        let indent = String(repeating: "  ", count: depth)
        
        if let node = FlowInstanceAttachments.default.instance(attachedTo: viewController) {
            let coordinatorName = node.coordinator.map { String(describing: type(of: $0)) } ?? "nil"
            output += "\(indent)- \(coordinatorName) (attached to \(type(of: viewController)))\n"
            
            for child in node.children {
                dumpNode(child, depth: depth + 1, output: &output)
            }
        }
        
        for childVC in viewController.children {
            dump(viewController: childVC, depth: depth, output: &output)
        }
        
        if let presented = viewController.presentedViewController {
            dump(viewController: presented, depth: depth + 1, output: &output)
        }
    }
    
    @MainActor
    private static func dumpNode(_ node: FlowNode, depth: Int, output: inout String) {
        let indent = String(repeating: "  ", count: depth)
        let coordinatorName = node.coordinator.map { String(describing: type(of: $0)) } ?? "nil"
        output += "\(indent)- [Child Node] \(coordinatorName)\n"
        for child in node.children {
            dumpNode(child, depth: depth + 1, output: &output)
        }
    }
}
#endif
