import UIKit

@MainActor
public protocol FlowNodesManaging: AnyObject {
    func attach(to viewController: UIViewController)
    func updateChildViewControllers(_ childVCs: [UIViewController])
}
