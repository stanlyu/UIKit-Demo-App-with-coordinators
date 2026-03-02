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
