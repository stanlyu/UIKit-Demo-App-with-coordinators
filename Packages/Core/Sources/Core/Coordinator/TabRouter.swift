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
public final class TabRouter {
    /// Инициализирует роутер для управления вкладками.
    ///
    /// - Parameters:
    ///   - coordinator: Координатор, который будет управлять данным роутером.
    ///   - tabBarController: Корневой `UITabBarController`. По умолчанию создается новый.
    ///   - lifecycleManager: Менеджер жизненного цикла. По умолчанию используется реализация через ассоциированные объекты.
    @MainActor
    public init(
        coordinator: _BaseCoordinator<TabRouter>, 
        tabBarController: UITabBarController = UITabBarController(),
        lifecycleManager: any LifecycleManaging = AssociatedObjectLifecycleManager()
    ) {
        self.coordinator = coordinator
        self.tabBarController = tabBarController
        self.unextractedRoot = tabBarController
        self.lifecycleManager = lifecycleManager
    }

    // MARK: - Private members

    private let coordinator: _BaseCoordinator<TabRouter>
    private weak var tabBarController: UITabBarController?
    private var unextractedRoot: UITabBarController?
    private let lifecycleManager: any LifecycleManaging
}

// MARK: - RoutingContext

extension TabRouter: RoutingContext {

    /// Непрозрачная обертка для корневого `UIViewController`, которым управляет этот роутер.
    public var root: RouterRoot { 
        guard let tabBarController = tabBarController ?? unextractedRoot else {
            fatalError("TabRouter's tab bar controller was deallocated or not set.")
        }
        return RouterRoot(tabBarController)
    }

    /// Извлекает корневой `UITabBarController`, которым управляет вкладка.
    ///
    /// - Returns: `UIViewController` кастованый как корневой таб бар контроллер.
    public func extractRootUI() -> UIViewController {
        coordinator.start(with: self)
        
        guard let tab = tabBarController ?? unextractedRoot else {
            fatalError("TabRouter's tab bar controller was deallocated or not set.")
        }
        lifecycleManager.retain(self, to: tab)
        unextractedRoot = nil
        return tab
    }
}

// MARK: - TabRouting

extension TabRouter: TabRouting {
    /// Текущий выбранный индекс вкладки.
    public var selectedIndex: Int {
        guard let tabBarController = tabBarController ?? unextractedRoot else {
            fatalError("TabRouter's tab bar controller was deallocated or not set.")
        }
        return tabBarController.selectedIndex
    }

    /// Текущий выбранный элемент вкладки (возвращает `RouterItem`).
    public var selectedItem: RouterItem? {
        guard let tabBarController = tabBarController ?? unextractedRoot else {
            fatalError("TabRouter's tab bar controller was deallocated or not set.")
        }
        guard let selected = tabBarController.selectedViewController else { return nil }
        return RouterItem(selected)
    }

    /// Заполняет роутер новыми элементами экранов.
    ///
    /// - Parameters:
    ///   - items: Массив экранов, которые должны стать вкладками `UITabBarController`.
    ///   - animated: Использовать ли UI-анимации для переустановки вкладок.
    public func setItems(_ items: [RouterItem], animated: Bool) {
        guard let tabBarController = tabBarController ?? unextractedRoot else {
            fatalError("TabRouter's tab bar controller was deallocated or not set.")
        }
        tabBarController.setViewControllers(items.map { $0.resolveViewController(parentRuntime: nil) }, animated: animated)
    }

    /// Выбирает определенную вкладку по её индексу.
    ///
    /// - Parameter index: Индекс окна, которое нужно сделать выделенным.
    public func selectTab(at index: Int) {
        guard let tabBarController = tabBarController ?? unextractedRoot else {
            fatalError("TabRouter's tab bar controller was deallocated or not set.")
        }
        tabBarController.selectedIndex = index
    }

    /// Выбирает определенную вкладку по переданному объекту `RouterItem`.
    ///
    /// Ищет совпадение переданного контроллера во внутреннем массиве.
    ///
    /// - Parameter item: Объект вью контроллера, который нужно сделать выделенным.
    public func selectItem(_ item: RouterItem) {
        guard let tabBarController = tabBarController ?? unextractedRoot else {
            fatalError("TabRouter's tab bar controller was deallocated or not set.")
        }
        if let viewControllers = tabBarController.viewControllers,
           let index = viewControllers.firstIndex(where: { item.isWrapping($0) }) {
            tabBarController.selectedIndex = index
        }
    }
}
