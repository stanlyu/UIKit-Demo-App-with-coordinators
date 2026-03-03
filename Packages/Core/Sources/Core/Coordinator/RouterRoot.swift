//
//  RouterRoot.swift
//  Core
//
//

import UIKit

/// Непрозрачная обёртка корневого UIViewController роутера.
public struct RouterRoot {
    internal let viewController: UIViewController
    
    internal init(_ viewController: UIViewController) {
        self.viewController = viewController
    }
}
