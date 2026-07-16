import UIKit

/// Контекст запуска координатора.
///
/// Создаётся только инфраструктурой навигации, поэтому внешний код не может
/// вручную запустить координатор через `start(_:)`.
public struct CoordinatorStartContext {
    init() {}
}

/// Базовый координатор модели flow.
///
/// Хранит навигационный интерфейс и type-erased компоузер. Конкретный компоузер
/// умеет строить `UIViewController`, но координатор получает только `RouterItem`
/// через `ComposerBox`.
///
/// Соответствует `Coordinating`: по умолчанию не обрабатывает интенты
/// (`receive(_:) -> false`). Наследники переопределяют `receive(_:)`, чтобы
/// реагировать на пуши, диплинки и universal links.
@MainActor
open class BaseCoordinator<Navigation, Route>: Coordinating {
    /// Навигационный интерфейс координатора (роутер).
    public let router: Navigation
    /// Type-erased компоузер для построения навигационных элементов по маршруту.
    public let composer: ComposerBox<Route>

    /// - Parameters:
    ///   - router: Навигационный интерфейс.
    ///   - composer: Компоузер, строящий экраны по маршрутам типа `Route`.
    public init<C: Composing>(
        router: Navigation,
        composer: C
    ) where C.Route == Route {
        self.router = router
        self.composer = ComposerBox(wrappedComposer: composer)
    }

    /// Запускает координатор: устанавливает корневой контент и выполняет
    /// первоначальную навигацию.
    ///
    /// - Parameter context: Системный контекст запуска.
    open func start(_ context: CoordinatorStartContext) {
        fatalError("Метод start(_:) должен быть переопределен в наследнике \(String(describing: self))")
    }
}
