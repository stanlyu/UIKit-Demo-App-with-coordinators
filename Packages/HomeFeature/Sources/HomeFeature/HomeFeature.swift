//
//  HomeInterfaces.swift
//  Demo App With Coordinators
//
//  Created by Любченко Станислав Валерьевич on 18.12.2025.
//

import UIKit
import Core

@MainActor
public protocol HomeExternalScreensProvider: AnyObject {
    func makePickupPointsViewController(onClose: @escaping () -> Void) -> UIViewController
}

@MainActor
public struct HomeBusinessDependencies {
    public let externalScreensProvider: any HomeExternalScreensProvider
    public init(externalScreensProvider: any HomeExternalScreensProvider) {
        self.externalScreensProvider = externalScreensProvider
    }
}

public enum HomeNavigationOutputEvent {
    case placeOrder(orderID: Int)
}

@MainActor
public enum HomeModule {
    public static func create(
        dependencies: HomeBusinessDependencies,
        onEvent: @escaping (HomeNavigationOutputEvent) -> Void
    ) -> UIViewController {
        FlowBuilder.stack(
            makeNavigationController: {
                let nav = UINavigationController()
                nav.navigationBar.prefersLargeTitles = true
                return nav
            },
            composer: HomeComposer(dependencies: dependencies)
        ) { router, composer in
            HomeCoordinator(
                router: router,
                composer: composer,
                onEvent: onEvent
            )
        }.viewController
    }
}
