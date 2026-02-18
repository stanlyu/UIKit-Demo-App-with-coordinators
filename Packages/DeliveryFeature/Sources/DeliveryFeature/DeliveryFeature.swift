//
//  DeliveryFeature.swift
//  DeliveryFeature
//
//  Created by Любченко Станислав Валерьевич on 22.12.2025.
//

import UIKit
import Core

@MainActor
public func pickupPointsViewController(
    embeddedInNavigationStack: Bool = false,
    dependencies: DeliveryDependencies
) -> UIViewController {
    if embeddedInNavigationStack {
        let coordinator = DeliveryInlineCoordinator(composer: DeliveryComposer(dependencies: dependencies))
        let router = InlineRouter(coordinator: coordinator)
        return router
    } else {
        let coordinator = DeliveryStackCoordinator(composer: DeliveryComposer(dependencies: dependencies))
        let router = StackRouter(coordinator: coordinator)
        router.navigationBar.prefersLargeTitles = true
        return router
    }
}

@MainActor
public func pickupPointsManager() -> PickupPointsManaging {
    PickupPointsManager()
}
