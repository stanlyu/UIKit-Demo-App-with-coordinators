//
//  DeliveryFeature.swift
//  DeliveryFeature
//
//  Created by Любченко Станислав Валерьевич on 22.12.2025.
//

import UIKit
import Core

public enum DeliveryFlowEvent {
    case closed
}

@MainActor
public func pickupPointsViewController(
    embeddedInNavigationStack: Bool = false,
    dependencies: DeliveryDependencies,
    eventHandler: ((DeliveryFlowEvent) -> Void)? = nil
) -> UIViewController {
    if embeddedInNavigationStack {
        let coordinator = DeliveryInlineCoordinator(
            composer: DeliveryComposer(dependencies: dependencies, showsBackButtonOnRoot: true),
            flowEventHandler: eventHandler
        )
        let router = InlineRouter(coordinator: coordinator)
        return router.extractRootUI()
    } else {
        let coordinator = DeliveryStackCoordinator(
            composer: DeliveryComposer(dependencies: dependencies, showsBackButtonOnRoot: false),
            flowEventHandler: eventHandler
        )
        let nav = UINavigationController()
        nav.navigationBar.prefersLargeTitles = true
        let router = StackRouter(coordinator: coordinator, navigationController: nav)
        return router.extractRootUI()
    }
}

@MainActor
public func pickupPointsManager() -> PickupPointsManaging {
    PickupPointsManager()
}
