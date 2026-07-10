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

    internal func setAttachmentManager(_ attachmentManager: any FlowAttachmentManaging) {
        self.attachmentManager = attachmentManager
    }

    public final func makeItem(for route: Route) -> RouterItem {
        let vc = makeViewController(route)
        owner?.adoptTaggedChild(from: vc)
        return RouterItem(
            vc,
            runtime: attachmentManager.runtime(attachedTo: vc)
        )
    }

    // MARK: - Private members

    internal weak var owner: ChildAdopting?
    private var attachmentManager: any FlowAttachmentManaging = FlowAttachmentManager.default
    private let makeViewController: @MainActor (Route) -> UIViewController
}
