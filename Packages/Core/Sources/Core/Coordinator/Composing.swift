//
//  Composing.swift
//  Core
//
//  Created by Codex on 27.02.2026.
//

import UIKit

/// Контракт для компоузеров, которые собирают `UIViewController` по route.
///
/// Внешний модуль реализует только этот протокол. Конвертация в
/// `RouterItem` выполняется инфраструктурой `Core`.
@MainActor
public protocol Composing {
    associatedtype Route

    func makeViewController(for route: Route) -> UIViewController
}

/// Простой компоузер, инициализируемый замыканием.
/// Полезен для простых флоу, где не требуется создание отдельного класса компоузера.
@MainActor
public struct InlineComposer<Route>: Composing {
    public let buildBlock: @MainActor @Sendable (Route) -> UIViewController
    
    public init(buildBlock: @MainActor @Sendable @escaping (Route) -> UIViewController) {
        self.buildBlock = buildBlock
    }
    
    public func makeViewController(for route: Route) -> UIViewController {
        return buildBlock(route)
    }
}
