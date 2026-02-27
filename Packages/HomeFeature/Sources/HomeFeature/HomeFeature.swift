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
    let container = StackContainer(coordinator: coordinator)
    container.navigationBar.prefersLargeTitles = true
    return container
}
