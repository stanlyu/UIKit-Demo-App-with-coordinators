import UIKit

/// Непрозрачная единица отображения для координаторов/роутеров.
///
/// `UIViewController` инкапсулирован внутри `Core`, чтобы координаторы
/// и внешние модули работали через абстракцию роутера.
@MainActor
public struct RouterItem {
    let viewController: UIViewController

    public init(_ viewController: UIViewController) {
        self.viewController = viewController
    }

    func isWrapping(_ viewController: UIViewController) -> Bool {
        self.viewController === viewController
    }
}
