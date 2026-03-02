//
//  ContainerItem.swift
//  Core
//
//  Created by Codex on 27.02.2026.
//

import UIKit

/// Непрозрачная единица отображения для контейнеров/роутеров.
///
/// `UIViewController` инкапсулирован внутри `Core`, чтобы координаторы
/// и внешние модули работали через абстракцию контейнера.
public struct ContainerItem {
    public let viewController: UIViewController

    public init(_ viewController: UIViewController) {
        self.viewController = viewController
    }
}
