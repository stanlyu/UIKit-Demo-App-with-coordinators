//
//  ComposerBox.swift
//  Core
//
//  Created by Codex on 27.02.2026.
//

import UIKit

/// Type-erasure обертка над конкретным `Composing`.
///
/// Предоставляет координатору безопасный API для получения `RouterItem` по route.
@MainActor
public final class ComposerBox<Route> {
    internal init<C: Composing>(wrappedComposer: C) where C.Route == Route {
        self.makeViewController = { route in
            wrappedComposer.makeViewController(for: route)
        }
    }

    public final func makeItem(for route: Route) -> RouterItem {
        RouterItem(makeViewController(route))
    }

    // MARK: - Private members

    private let makeViewController: @MainActor (Route) -> UIViewController
}
