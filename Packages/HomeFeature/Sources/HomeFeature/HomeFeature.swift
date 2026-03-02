//
//  HomeInterfaces.swift
//  Demo App With Coordinators
//
//  Created by Любченко Станислав Валерьевич on 18.12.2025.
//

import UIKit
import Core

public enum HomeEvent {
    case placeOrder(Int)
}

@MainActor
public func homeViewController(
    with eventHandler: @escaping (HomeEvent) -> Void,
    dependencies: HomeDependencies
) -> UIViewController {
    let coordinator = HomeCoordinator(
        composer: HomeComposer(dependencies: dependencies),
        eventHandler: eventHandler
    )
    let nav = UINavigationController()
    nav.navigationBar.prefersLargeTitles = true
    let router = StackRouter(coordinator: coordinator, navigationController: nav)
    return router.extractRootUI()
}
