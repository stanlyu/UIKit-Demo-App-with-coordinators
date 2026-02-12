//
//  TabRouter.swift
//  Core
//
//  Created by Любченко Станислав Валерьевич on 12.02.2026.
//

import UIKit

/// Роутер, владеющий **панелью вкладок** (`UITabBarController`).
public final class TabRouter: UITabBarController {

    /// Инициализирует роутер с заданным координатором.
    /// - Parameter coordinator: Координатор, который будет управлять этим роутером.
    public init(coordinator: Coordinator) {
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        // Старт откладываем на следующий тик main loop, чтобы внешний composer успел
        // связать coordinator с router (BaseCoordinator.router) до начала flow.
        Task { @MainActor in
            coordinator.start()
        }
    }

    // MARK: - Private members

    private let coordinator: Coordinator
}

extension TabRouter: TabRouting {
    public var selectedModule: UIViewController? {
        selectedViewController
    }

    public func setTabs(_ modules: [UIViewController], animated: Bool) {
        setViewControllers(modules, animated: animated)
    }

    public func selectTab(at index: Int) {
        selectedIndex = index
    }

    public func selectModule(_ module: UIViewController) {
        if let viewControllers = viewControllers,
           let index = viewControllers.firstIndex(of: module) {
            selectedIndex = index
        }
    }
}
