//
//  TabContainer.swift
//  Core
//
//  Created by Любченко Станислав Валерьевич on 12.02.2026.
//

import UIKit

/// Контейнер, владеющий **панелью вкладок Tab Bar** (`UITabBarController`).
public final class TabContainer: UITabBarController {

    /// Инициализирует контейнер с заданным координатором.
    /// - Parameter coordinator: Координатор, который будет управлять этим контейнером.
    public init(coordinator: Coordinator<TabContainer>) {
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

    private let coordinator: Coordinator<TabContainer>
}

extension TabContainer: TabRouting {

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
