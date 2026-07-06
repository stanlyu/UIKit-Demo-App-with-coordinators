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
        let coordinator = HomeCoordinator(
            composer: HomeComposer(),
            onEvent: onEvent
        )
        let nav = UINavigationController()
        nav.navigationBar.prefersLargeTitles = true
        let router = StackRouter(coordinator: coordinator, navigationController: nav)
        return router.extractRootUI()
    }
}
