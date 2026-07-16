import UIKit

/// Type-erased обёртка над конкретным `Composing`.
///
/// Даёт координатору безопасный API получения навигационного элемента по
/// маршруту, скрывая конкретный тип компоузера и сам `UIViewController` внутри
/// инфраструктуры. Координатор работает только с `RouterItem` и не касается
/// контроллеров экранов напрямую.
@MainActor
public final class ComposerBox<Route> {
    init<C: Composing>(wrappedComposer: C) where C.Route == Route {
        self.makeRouterItem = { route in
            let viewController = wrappedComposer.makeViewController(for: route)
            return RouterItem(viewController)
        }
    }

    /// Строит навигационный элемент для заданного маршрута.
    ///
    /// - Parameter route: Маршрут, для которого строится элемент.
    /// - Returns: Готовый `RouterItem`.
    public final func makeItem(for route: Route) -> RouterItem {
        makeRouterItem(route)
    }

    // MARK: - Private members

    private let makeRouterItem: @MainActor (Route) -> RouterItem
}
