import UIKit

/// Контракт компоузера: строит `UIViewController` по маршруту (route).
///
/// Внешний модуль реализует только этот протокол — конкретную логику создания
/// экранов. Преобразование результата в `RouterItem` берёт на себя
/// инфраструктура навигации, поэтому координаторы не работают с `UIViewController`
/// напрямую.
@MainActor
public protocol Composing {
    /// Тип маршрута, по которому компоузер строит экраны.
    associatedtype Route

    /// Возвращает экран для заданного маршрута.
    ///
    /// - Parameter route: Маршрут, для которого нужно создать экран.
    /// - Returns: Контроллер экрана.
    func makeViewController(for route: Route) -> UIViewController
}

/// Простой компоузер, собирающий экран замыканием.
///
/// Удобен для несложных flow, где не нужна отдельная реализация `Composing`:
/// достаточно передать замыкание, строящее экран по маршруту.
@MainActor
public struct InlineComposer<Route>: Composing {
    public let buildBlock: @MainActor @Sendable (Route) -> UIViewController

    /// - Parameter buildBlock: Замыкание, создающее экран по маршруту.
    public init(buildBlock: @MainActor @Sendable @escaping (Route) -> UIViewController) {
        self.buildBlock = buildBlock
    }

    public func makeViewController(for route: Route) -> UIViewController {
        return buildBlock(route)
    }
}
