//
//  ComposerBox.swift
//  Core
//
//  Created by Codex on 27.02.2026.
//

import UIKit

/// Type-erasure обертка над конкретным `Composing`.
///
/// Хранит capability внутри `Core` и предоставляет координатору безопасный API
/// для получения `ContainerItem` по route.
@MainActor
public final class ComposerBox<Route> {
    internal init<C: Composing>(wrappedComposer: C, capability: ComposeCapability) where C.Route == Route {
        self.capability = capability
        self.makeViewController = { route in
            wrappedComposer.makeViewController(for: route, capability: capability)
        }
    }

    public final func makeItem(for route: Route) -> ContainerItem {
        ContainerItem(makeViewController(route))
    }

    // MARK: - Private members

    private let capability: ComposeCapability
    private let makeViewController: @MainActor (Route) -> UIViewController
}
