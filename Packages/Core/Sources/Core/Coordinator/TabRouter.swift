//
//  TabRouter.swift
//  Core
//
//  Created by Любченко Станислав Валерьевич on 12.02.2026.
//

import UIKit

/// Роутер, владеющий **панелью вкладок Tab Bar** (`UITabBarController`).
public final class TabRouter: UITabBarController {

    /// Инициализирует роутер с заданным координатором.
    /// - Parameter coordinator: Координатор, который будет управлять этим роутером.
    public init(coordinator: Coordinator<TabRouter>) {
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        coordinator.start(with: self)
    }

    // MARK: - Private members

    private let coordinator: Coordinator<TabRouter>
}

extension TabRouter: TabRouting {

    public func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        super.setViewControllers(viewControllers, animated: animated)
    }

    public func selectTab(at index: Int) {
        selectedIndex = index
    }

    public func selectViewController(_ viewController: UIViewController) {
        if let viewControllers = viewControllers,
           let index = viewControllers.firstIndex(of: viewController) {
            selectedIndex = index
        }
    }
}
