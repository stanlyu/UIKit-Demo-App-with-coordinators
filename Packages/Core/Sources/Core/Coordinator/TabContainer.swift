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
    public init(coordinator: BaseCoordinator<TabContainer>) {
        self.startFlow = { container in
            coordinator.start(with: container)
        }
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        startFlow(self)
    }

    // MARK: - Private members

    private let startFlow: (TabContainer) -> Void
}

extension TabContainer: TabRouting {

    public var selectedItem: ContainerItem? {
        guard let selectedViewController else { return nil }
        return ContainerItem(selectedViewController)
    }

    public func setItems(_ items: [ContainerItem], animated: Bool) {
        super.setViewControllers(items.map(\.viewController), animated: animated)
    }

    public func selectTab(at index: Int) {
        selectedIndex = index
    }

    public func selectItem(_ item: ContainerItem) {
        if let viewControllers = viewControllers,
           let index = viewControllers.firstIndex(where: { $0 === item.viewController }) {
            selectedIndex = index
        }
    }
}
