import UIKit

/// Результат сборки flow.
///
/// `viewController` возвращается наружу как публичный контракт модуля.
/// `coordinator` оставлен для сценариев, где координатор реализует
/// `NavigationInput`.
@MainActor
public struct CreatedFlow<Coordinator: AnyObject> {
    public let viewController: UIViewController
    public let coordinator: Coordinator

    init(viewController: UIViewController, coordinator: Coordinator) {
        self.viewController = viewController
        self.coordinator = coordinator
    }
}
