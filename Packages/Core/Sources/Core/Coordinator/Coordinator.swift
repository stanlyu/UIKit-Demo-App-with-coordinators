import UIKit

/// Базовый абстрактный класс координатора.
///
/// Является связующим звеном между инфраструктурой навигации (Роутером) и навигационной логикой.
/// Управляет жизненным циклом потока и обеспечивает типобезопасный доступ к методам навигации.
///
/// - Generic Parameter R: Тип роутера (`Routing`), с которым работает данный координатор.
/// - Generic Parameter Route: Тип маршрута, который использует компоузер координатора.
@MainActor
open class Coordinator<R: Routing, Route>: Coordinating {

    /// Capability-токен, подтверждающий право запустить координатор.
    public struct Start<Router: Routing> {
        internal init() {}
    }

    /// Псевдоним capability-токена запуска для текущего типа координатора.
    public typealias StartCapability = Start<R>

    /// Роутер, через который осуществляется навигация.
    ///
    /// - Warning: Безопасный доступ гарантирован только внутри метода `start(_:)` и после него.
    public var router: R? {
        return _router
    }

    /// Компоузер-обертка, связанная с этим координатором.
    public private(set) var composer: ComposerBox<Route>

    /// Инициализирует координатор с конкретным компоузером.
    ///
    /// - Parameter composer: Компоузер, собирающий `UIViewController` для данного `Route`.
    public init<C: Composing>(composer: C) where C.Route == Route {
        self.composer = ComposerBox(wrappedComposer: composer)
    }

    /// Служебная точка входа для связывания Роутера и Координатора.
    ///
    /// - Note: Метод помечен как `final`, так как основная логика запуска должна быть в `start(_: StartCapability)`.
    public final func start(with router: R) {
        guard _router == nil else { return }
        _router = router
        start(.init())
    }

    /// Точка входа в бизнес-логику навигации.
    ///
    /// - Parameter capability: Маркер права на запуск, создаваемый инфраструктурой Core.
    /// - Warning: Базовая реализация вызывает `fatalError`. Метод должен быть переопределен.
    open func start(_ capability: StartCapability) {
        fatalError("Метод start(_:) должен быть переопределен в наследнике \(String(describing: self))")
    }

    // MARK: - Private members

    private weak var _router: R?
}
