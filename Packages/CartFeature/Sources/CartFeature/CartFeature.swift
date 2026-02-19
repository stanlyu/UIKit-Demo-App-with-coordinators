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

public enum CartEvent {
    case changePickupPoint(CartInput)
    case continueToPayment(CartInput)
}

@MainActor
public protocol CartInput: AnyObject {
    func presentPickupPoints(viewController: UIViewController)
    func showPayment(viewController: UIViewController)
    func closePayment()
    func placeOrder(_ orderID: Int)
    func completePayment(with result: CartPaymentResult)
}

public typealias CartModule = (viewController: UIViewController, coordinator: CartInput)

@MainActor
public func cartModule(
    with eventHandler: @escaping (CartEvent) -> Void,
    dependencies: CartDependencies
) -> CartModule {
    let coordinator = CartCoordinator(
        composer: CartComposer(dependencies: dependencies),
        eventHandler: eventHandler
    )
    let router = StackRouter(coordinator: coordinator)
    router.navigationBar.prefersLargeTitles = true
    return (router, coordinator)
}
