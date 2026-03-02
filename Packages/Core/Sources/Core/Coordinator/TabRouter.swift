//
//  TabRouter.swift
//  Core
//
//  Created by Любченко Станислав Валерьевич on 12.02.2026.
//

import UIKit

import ObjectiveC

/// Роутер, управляющий вкладками (UITabBarController).
@MainActor
public final class TabRouter: TabRouting {
    private weak var tabBarController: UITabBarController!
    private let _startCoordinator: (TabRouter) -> Void
    private var hasStarted: Bool = false

    public init<C: Coordinating>(coordinator: C, tabBarController: UITabBarController = UITabBarController()) where C.R == TabRouter {
        self.tabBarController = tabBarController
        self._startCoordinator = { router in
            coordinator.start(with: router)
        }
        
        self.bindLifecycle(to: tabBarController)
    }

    /// Извлекает корневой `UITabBarController`, которым управляет вкладка.
    ///
    /// - Returns: `UIViewController` кастованый как корневой таб бар контроллер.
    public func extractRootUI() -> UIViewController {
        if !hasStarted {
            hasStarted = true
            _startCoordinator(self)
        }
        
        guard let tab = tabBarController else {
            fatalError("TabRouter's tab bar controller was deallocated or not set.")
        }
        return tab
    }

    public var selectedIndex: Int {
        tabBarController.selectedIndex
    }

    public var selectedItem: RouterItem? {
        guard let selected = tabBarController.selectedViewController else { return nil }
        return RouterItem(selected)
    }

    /// Заполняет роутер новыми элементами экранов.
    ///
    /// - Parameters:
    ///   - items: Массив экранов, которые должны стать вкладками `UITabBarController`.
    ///   - animated: Использовать ли UI-анимации для переустановки вкладок.
    public func setItems(_ items: [RouterItem], animated: Bool) {
        tabBarController.setViewControllers(items.map(\.viewController), animated: animated)
    }

    /// Выбирает определенную вкладку по её индексу.
    ///
    /// - Parameter index: Индекс окна, которое нужно сделать выделенным.
    public func selectTab(at index: Int) {
        tabBarController.selectedIndex = index
    }

    /// Выбирает определенную вкладку по переданному объекту `RouterItem`.
    ///
    /// Ищет совпадение переданного контроллера во внутреннем массиве.
    ///
    /// - Parameter item: Объект вью контроллера, который нужно сделать выделенным.
    public func selectItem(_ item: RouterItem) {
        if let viewControllers = tabBarController.viewControllers,
           let index = viewControllers.firstIndex(where: { $0 === item.viewController }) {
            tabBarController.selectedIndex = index
        }
    }
}
