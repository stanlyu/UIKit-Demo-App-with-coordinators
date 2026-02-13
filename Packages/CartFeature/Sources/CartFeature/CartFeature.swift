//
//  CartInterfaces.swift
//  Demo App With Coordinators
//
//  Created by Любченко Станислав Валерьевич on 18.12.2025.
//

import UIKit
import Core

@MainActor
public protocol CartCoordinating {
    func presentPickupPoints(module: UIViewController)
}

public enum CartEvent {
    case changePickupPoint(CartCoordinating)
}

@MainActor
public protocol CartInput {
    func placeOrder(_ orderID: Int)
}

public typealias CartModule = (viewController: UIViewController, coordinator: CartInput)

@MainActor
public func cartModule(with eventHandler: @escaping (CartEvent) -> Void) -> CartModule {
    let coordinator = CartCoordinator(composer: CartComposer(), eventHandler: eventHandler)
    let router = StackRouter(coordinator: coordinator)
    router.navigationBar.prefersLargeTitles = true
    return (router, coordinator)
}
