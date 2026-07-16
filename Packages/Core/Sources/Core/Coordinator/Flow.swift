import UIKit

/// Результат сборки flow.
///
/// `viewController` — это публичный контракт, который возвращается наружу и
/// встраивается в интерфейс. `coordinator` оставлен доступным для сценариев,
/// где координатор реализует дополнительный внешний контракт (например,
/// принимает интенты или команды навигации).
@MainActor
public struct Flow<Coordinator: AnyObject> {
    /// Корневой контроллер собранного flow.
    public let viewController: UIViewController
    /// Координатор, управляющий flow.
    public let coordinator: Coordinator

    init(viewController: UIViewController, coordinator: Coordinator) {
        self.viewController = viewController
        self.coordinator = coordinator
    }
}
