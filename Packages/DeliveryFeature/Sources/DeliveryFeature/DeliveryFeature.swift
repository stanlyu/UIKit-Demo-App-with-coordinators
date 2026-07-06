//
//  DeliveryFeature.swift
//  DeliveryFeature
//
//  Created by Любченко Станислав Валерьевич on 22.12.2025.
//

import UIKit
import Core

public enum PickupPointNavigationOutputEvent {
    case didClose
}

@MainActor
public enum PickupPointModule {
    public static func makePickupPointsManager() -> PickupPointsManaging {
        PickupPointsManager()
    }

    public static func create(
        embeddedInNavigationStack: Bool = false,
        dependencies: PickupPointBusinessDependencies,
        onEvent: ((PickupPointNavigationOutputEvent) -> Void)? = nil
    ) -> UIViewController {
        if embeddedInNavigationStack {
            let coordinator = DeliveryInlineCoordinator(
                composer: DeliveryComposer(dependencies: dependencies, rootNavigationControl: .backButton),
                onEvent: onEvent
            )
            let router = InlineRouter(coordinator: coordinator)
            return router.extractRootUI()
        } else {
            let coordinator = DeliveryStackCoordinator(
                composer: DeliveryComposer(dependencies: dependencies, rootNavigationControl: .closeButton),
                onEvent: onEvent
            )
            let nav = UINavigationController()
            nav.navigationBar.prefersLargeTitles = true
            let router = StackRouter(coordinator: coordinator, navigationController: nav)
            return router.extractRootUI()
        }
    }
}
