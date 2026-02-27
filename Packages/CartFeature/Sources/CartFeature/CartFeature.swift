//
//  CartInterfaces.swift
//  Demo App With Coordinators
//
//  Created by Любченко Станислав Валерьевич on 18.12.2025.
//

import UIKit
import Core

public enum CartPaymentError: Sendable {
    case insufficientFunds
    case cardExpired
    case bankDeclined
    case networkUnavailable
    case processingTimeout
}

public enum CartPaymentResult: Sendable {
    case success(amount: Int)
    case failure(amount: Int, error: CartPaymentError)
}

@MainActor
public protocol CartInput: AnyObject {
    func placeOrder(_ orderID: Int)
}

public typealias CartModule = (viewController: UIViewController, coordinator: CartInput)

@MainActor
public func cartModule(dependencies: CartDependencies) -> CartModule {
    let coordinator = CartCoordinator(
        composer: CartComposer(dependencies: dependencies)
    )
    let container = StackContainer(coordinator: coordinator)
    container.navigationBar.prefersLargeTitles = true
    return (container, coordinator)
}
