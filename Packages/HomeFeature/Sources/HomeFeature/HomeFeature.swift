//
//  HomeInterfaces.swift
//  Demo App With Coordinators
//
//  Created by Любченко Станислав Валерьевич on 18.12.2025.
//

import UIKit
import Core

public enum HomeNavigationOutputEvent {
    case placeOrder(orderID: Int)
    case pickupPointsRequested(context: any NavigationStackContext, onClose: () -> Void)
}

@MainActor
public enum HomeModule {
    public static func create(
        onEvent: @escaping (HomeNavigationOutputEvent) -> Void
    ) -> UIViewController {
        Flow.stack(
            makeNavigationController: {
                let nav = UINavigationController()
                nav.navigationBar.prefersLargeTitles = true
                return nav
            },
            composer: HomeComposer()
        ) { router, composer in
            HomeCoordinator(
                router: router,
                composer: composer,
                onEvent: onEvent
            )
        }.viewController
    }
}
