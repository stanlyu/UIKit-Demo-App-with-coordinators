//
//  ComposerBox.swift
//  Core
//
//  Created by Codex on 27.02.2026.
//

import UIKit

/// Type-erasure обертка над конкретным `Composing`.
///
/// Предоставляет координатору безопасный API для получения opaque navigation item
/// по route. Доступ к `UIViewController` остается внутри `Core`.
@MainActor
public final class ComposerBox<Route> {
    init<C: Composing>(wrappedComposer: C) where C.Route == Route {
        self.makeRouterItem = { route in
            let viewController = wrappedComposer.makeViewController(for: route)
            return RouterItem(viewController)
        }
    }

    public final func makeItem(for route: Route) -> RouterItem {
        makeRouterItem(route)
    }

    // MARK: - Private members

    private let makeRouterItem: @MainActor (Route) -> RouterItem
}
