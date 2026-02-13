//
//  ApplicationCoordinator.swift
//  Demo App With Coordinators
//
//  Created by Любченко Станислав Валерьевич on 17.12.2025.
//

import UIKit
import Core

typealias ApplicationCoordinator = ApplicationCoordinatingLogic<WindowRouter>

final class ApplicationCoordinatingLogic<Router: WindowRouting>: Coordinator<Router> {

    init(composer: ApplicationComposing = ApplicationComposer()) {
        self.composer = composer
        super.init()
    }

    override func start() {
        let launchVC = composer.makeLaunchViewController { [unowned self] event in
            self.handleLaunchEvent(event)
        }
        router?.setRoot(launchVC, animated: false, completion: nil)
    }

    // MARK: - Private members

    private let composer: ApplicationComposing

    private func handleLaunchEvent(_ event: LaunchScreenEvent) {
        switch event {
        case .mainFlowStarted:
            router?.setRoot(composer.makeMainTabsViewController(), animated: true, completion: nil)
        }
    }
}
