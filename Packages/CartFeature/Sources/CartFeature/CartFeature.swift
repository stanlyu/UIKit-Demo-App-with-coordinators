//
//  CartInterfaces.swift
//  Demo App With Coordinators
//
//  Created by Любченко Станислав Валерьевич on 18.12.2025.
//

import UIKit

public enum CartEvent {
    case changePickupPoint
}

@MainActor
public protocol CartInput {
    func placeOrder(_ orderID: Int)
}

@MainActor
public func cartViewController(
    with inputProvider: (CartInput) -> Void,
    eventHandler: @escaping (CartEvent) -> Void
) -> UIViewController {
    let coordinator = CartCoordinator(composer: CartComposer(), eventHandler: eventHandler)
    inputProvider(coordinator)
    return coordinator
}
