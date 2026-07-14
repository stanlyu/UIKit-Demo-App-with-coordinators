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
    internal init<C: Composing>(wrappedComposer: C) where C.Route == Route {
        self.makeRouterItem = { route, attachmentManager in
            let viewController = wrappedComposer.makeViewController(for: route)
            return RouterItem(
                viewController,
                instance: attachmentManager.instance(attachedTo: viewController)
            )
        }
    }

    internal func setAttachmentManager(_ attachmentManager: any FlowInstanceAttachmentStoring) {
        self.attachmentManager = attachmentManager
    }

    public final func makeItem(for route: Route) -> RouterItem {
        makeRouterItem(route, attachmentManager)
    }

    // MARK: - Private members

    private var attachmentManager: any FlowInstanceAttachmentStoring = FlowInstanceAttachments.default
    private let makeRouterItem: @MainActor (Route, any FlowInstanceAttachmentStoring) -> RouterItem
}
