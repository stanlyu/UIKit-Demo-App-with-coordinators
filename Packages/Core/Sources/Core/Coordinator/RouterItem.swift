//
//  RouterItem.swift
//  Core
//
//  Created by Codex on 27.02.2026.
//

import UIKit

/// Непрозрачная единица отображения для координаторов/роутеров.
///
/// `UIViewController` инкапсулирован внутри `Core`, чтобы координаторы
/// и внешние модули работали через абстракцию роутера.
@MainActor
public struct RouterItem {
    internal let viewController: UIViewController
    internal let runtime: (any FlowRuntimeNode)?

    internal init(
        _ viewController: UIViewController,
        runtime: (any FlowRuntimeNode)? = nil
    ) {
        self.viewController = viewController
        self.runtime = runtime
    }

    internal func resolveViewController(parentRuntime: (any FlowRuntimeNode)?) -> UIViewController {
        return viewController
    }

    internal func isWrapping(_ viewController: UIViewController) -> Bool {
        self.viewController === viewController
    }
}
