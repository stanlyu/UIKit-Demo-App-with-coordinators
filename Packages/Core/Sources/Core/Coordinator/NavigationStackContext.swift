//
//  NavigationStackContext.swift
//  Core
//

import UIKit

/// Контекст, через который родительский координатор может выполнить переход
/// внутри навигационной области дочернего флоу, не раскрывая ему сборку внешнего модуля.
@MainActor
public protocol NavigationStackContext: AnyObject {
    func push(_ item: RouterItem, animated: Bool, completion: (() -> Void)?)
    func present(_ item: RouterItem, animated: Bool, completion: (() -> Void)?)
    func pop(animated: Bool, completion: (() -> Void)?)
    func dismiss(animated: Bool, completion: (() -> Void)?)
}

public extension NavigationStackContext {
    func push(_ item: RouterItem, animated: Bool) {
        push(item, animated: animated, completion: nil)
    }

    func present(_ item: RouterItem, animated: Bool) {
        present(item, animated: animated, completion: nil)
    }

    func pop(animated: Bool) {
        pop(animated: animated, completion: nil)
    }

    func dismiss(animated: Bool) {
        dismiss(animated: animated, completion: nil)
    }
}

/// Адаптер над `StackRouting` для передачи навигационных команд между флоу.
@MainActor
public final class RouterNavigationStackContext<Router: StackRouting>: NavigationStackContext {
    public init(router: Router) {
        self.router = router
    }

    public func push(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        router?.push(item, animated: animated, completion: completion)
    }

    public func present(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        router?.present(item, animated: animated, completion: completion)
    }

    public func pop(animated: Bool, completion: (() -> Void)?) {
        router?.pop(animated: animated, completion: completion)
    }

    public func dismiss(animated: Bool, completion: (() -> Void)?) {
        router?.dismiss(animated: animated, completion: completion)
    }

    // MARK: - Private members

    private weak var router: Router?
}
