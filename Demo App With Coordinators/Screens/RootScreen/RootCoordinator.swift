//
//  RootCoordinator.swift
//  Demo App With Coordinators
//
//  Created by Любченко Станислав Валерьевич on 17.12.2025.
//

import UIKit

final class RootCoordinator {

    weak var router: RootRouting?

    init(composer: RootComposing) {
        self.composer = composer
    }

    // MARK: - Private members

    private let composer: RootComposing

    private func handleLaunchEvent(_ event: LaunchScreenEvent) {
        switch event {
        case .mainFlowStarted:
            router?.routeToViewController(composer.makeMainTabsViewController())
        }
    }
}

protocol RootContentProviding: AnyObject {
    var content: UIViewController { get }
}

extension RootCoordinator: RootContentProviding {
    var content: UIViewController {
        composer.makeLaunchViewController(with: handleLaunchEvent)
    }
}
