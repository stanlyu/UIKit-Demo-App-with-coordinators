//
//  ApplicationComposer.swift
//  Demo App With Coordinators
//
//  Created by Любченко Станислав Валерьевич on 17.12.2025.
//

import UIKit

struct ApplicationComposer {
    func makeRootViewController() -> UIViewController {
        let composer = RootComposer()
        let coordinator = RootCoordinator(composer: composer)
        let router = RootRouter(contentProvider: coordinator)
        coordinator.router = router
        return router
    }
}
