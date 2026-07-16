import UIKit

/// Управляет узлом flow-инстанса: привязывает его к контроллеру экрана и
/// синхронизирует дочерние узлы с текущим набором контроллеров.
@MainActor
public protocol FlowNodesManaging: AnyObject {
    /// Привязывает узел координатора к контроллеру экрана.
    func attach(to viewController: UIViewController)

    /// Синхронизирует дочерние узлы с переданным набором контроллеров:
    /// усыновляет новые и удаляет отсутствующие.
    func updateChildViewControllers(_ childVCs: [UIViewController])
}
