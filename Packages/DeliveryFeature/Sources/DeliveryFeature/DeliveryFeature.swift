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
            return FlowBuilder.inline(
                composer: DeliveryComposer(dependencies: dependencies, rootNavigationControl: .backButton)
            ) { router, composer in
                DeliveryCoordinator(
                    router: router,
                    composer: composer,
                    onEvent: onEvent
                )
            }.viewController
        } else {
            return FlowBuilder.stack(
                makeNavigationController: {
                    let nav = UINavigationController()
                    nav.navigationBar.prefersLargeTitles = true
                    return nav
                },
                composer: DeliveryComposer(dependencies: dependencies, rootNavigationControl: .closeButton)
            ) { router, composer in
                DeliveryCoordinator(
                    router: router,
                    composer: composer,
                    onEvent: onEvent
                )
            }.viewController
        }
    }
}
