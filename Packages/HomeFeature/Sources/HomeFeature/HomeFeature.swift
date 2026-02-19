//
//  HomeInterfaces.swift
//  Demo App With Coordinators
//
//  Created by Любченко Станислав Валерьевич on 18.12.2025.
//

import UIKit
import Core

@MainActor
public protocol HomeInput {
    func presentPickupPoints(module: UIViewController)
}

public enum HomeEvent {
    case placeOrder(Int)
    case selectPickupPoint(HomeInput)
}

@MainActor
public func homeViewController(with eventHandler: @escaping (HomeEvent) -> Void) -> UIViewController {
    let coordinator = HomeCoordinator(composer: HomeComposer(), eventHandler: eventHandler)
    let router = StackRouter(coordinator: coordinator)
    router.navigationBar.prefersLargeTitles = true
    return router
}
