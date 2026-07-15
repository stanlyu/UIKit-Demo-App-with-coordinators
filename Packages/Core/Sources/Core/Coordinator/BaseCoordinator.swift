import UIKit

/// Контекст запуска координатора.
///
/// Создается только инфраструктурой `Core`, поэтому внешний код не может
/// вручную запустить координатор через `start(_:)`.
public struct CoordinatorStartContext {
    init() {}
}

/// Базовый координатор новой flow-модели.
///
/// Координатор хранит навигационный интерфейс и type-erased composer.
/// Concrete composer может создавать `UIViewController`, но координатор
/// получает только `RouterItem` через `ComposerBox`.
///
/// Соответствует `Coordinating`: по умолчанию не обрабатывает интенты
/// (`receive(_:) -> false`). Наследники могут переопределить `receive(_:)`,
/// чтобы реагировать на пушы/диплинки/universal links.
@MainActor
open class BaseCoordinator<Navigation, Route>: Coordinating {
    public let router: Navigation
    public let composer: ComposerBox<Route>

    public init<C: Composing>(
        router: Navigation,
        composer: C
    ) where C.Route == Route {
        self.router = router
        self.composer = ComposerBox(wrappedComposer: composer)
    }

    open func start(_ context: CoordinatorStartContext) {
        fatalError("Метод start(_:) должен быть переопределен в наследнике \(String(describing: self))")
    }
}
