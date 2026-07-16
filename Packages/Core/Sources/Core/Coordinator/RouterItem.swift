import UIKit

/// Непрозрачная единица навигации, с которой работают координаторы и роутеры.
///
/// `UIViewController` инкапсулирован внутри, чтобы координаторы и внешние
/// модули общались с навигацией через абстракцию роутера, а не через сам
/// контроллер.
@MainActor
public struct RouterItem {
    let viewController: UIViewController

    /// Создаёт элемент навигации, оборачивающий заданный контроллер экрана.
    ///
    /// - Parameter viewController: Контроллер экрана, оборачиваемый в элемент.
    public init(_ viewController: UIViewController) {
        self.viewController = viewController
    }

    /// Возвращает `true`, если элемент оборачивает заданный контроллер.
    func isWrapping(_ viewController: UIViewController) -> Bool {
        self.viewController === viewController
    }
}
