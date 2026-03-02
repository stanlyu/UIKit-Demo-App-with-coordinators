//
//  TabContainer.swift
//  Core
//
//  Created by Любченко Станислав Валерьевич on 12.02.2026.
//

import UIKit

import ObjectiveC

/// Контейнер, управляющий вкладками (UITabBarController).
@MainActor
public final class TabContainer: TabRouting {
    private weak var tabBarController: UITabBarController!
    private let coordinator: any Coordinating

    public init<C: Coordinating>(coordinator: C, tabBarController: UITabBarController = UITabBarController()) where C.R == TabContainer {
        self.tabBarController = tabBarController
        self.coordinator = coordinator
        
        self.bindLifecycle(to: tabBarController)
        coordinator.start(with: self)
    }

    /// Извлекает корневой `UITabBarController`, которым управляет вкладка.
    ///
    /// - Returns: `UIViewController` кастованый как корневой таб бар контроллер.
    public func extractContent() -> UIViewController {
        guard let tab = tabBarController else {
            fatalError("TabContainer's tab bar controller was deallocated or not set.")
        }
        return tab
    }

    public var selectedIndex: Int {
        tabBarController.selectedIndex
    }

    public var selectedItem: ContainerItem? {
        guard let selected = tabBarController.selectedViewController else { return nil }
        return ContainerItem(selected)
    }

    /// Заполняет контейнер новыми элементами экранов.
    ///
    /// - Parameters:
    ///   - items: Массив экранов, которые должны стать вкладками `UITabBarController`.
    ///   - animated: Использовать ли UI-анимации для переустановки вкладок.
    public func setItems(_ items: [ContainerItem], animated: Bool) {
        tabBarController.setViewControllers(items.map(\.viewController), animated: animated)
    }

    /// Выбирает определенную вкладку по её индексу.
    ///
    /// - Parameter index: Индекс окна, которое нужно сделать выделенным.
    public func selectTab(at index: Int) {
        tabBarController.selectedIndex = index
    }

    /// Выбирает определенную вкладку по переданному объекту `ContainerItem`.
    ///
    /// Ищет совпадение переданного контроллера во внутреннем массиве.
    ///
    /// - Parameter item: Объект вью контроллера, который нужно сделать выделенным.
    public func selectItem(_ item: ContainerItem) {
        if let viewControllers = tabBarController.viewControllers,
           let index = viewControllers.firstIndex(where: { $0 === item.viewController }) {
            tabBarController.selectedIndex = index
        }
    }
}
