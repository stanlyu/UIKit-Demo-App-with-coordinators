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
        let container = InlineContainer(coordinator: coordinator)
        return container
    } else {
        let coordinator = DeliveryStackCoordinator(
            composer: DeliveryComposer(dependencies: dependencies, showsBackButtonOnRoot: false),
            flowEventHandler: eventHandler
        )
        let container = StackContainer(coordinator: coordinator)
        container.navigationBar.prefersLargeTitles = true
        return container
    }
}

@MainActor
public func pickupPointsManager() -> PickupPointsManaging {
    PickupPointsManager()
}
