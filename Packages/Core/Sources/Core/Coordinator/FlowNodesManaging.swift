import UIKit

@MainActor
public protocol FlowNodesManaging: AnyObject {
    func updateParentViewController(_ parentVC: UIViewController?)
    func updateChildViewControllers(_ childVCs: [UIViewController])
}
