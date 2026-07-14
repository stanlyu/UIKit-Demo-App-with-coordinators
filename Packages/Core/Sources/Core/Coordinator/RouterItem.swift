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
    internal let instance: (any FlowInstanceNode)?

    internal init(
        _ viewController: UIViewController,
        instance: (any FlowInstanceNode)? = nil
    ) {
        self.viewController = viewController
        self.instance = instance
    }

    internal func isWrapping(_ viewController: UIViewController) -> Bool {
        self.viewController === viewController
    }
}
