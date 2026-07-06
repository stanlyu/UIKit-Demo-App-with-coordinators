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
public protocol CartNavigationInput: AnyObject {
    func placeOrder(_ orderID: Int)
}

public enum CartNavigationOutputEvent {
    case pickupPointsRequested(context: any NavigationStackContext, onClose: () -> Void)
    case paymentRequested(context: any NavigationStackContext, onComplete: (CartPaymentResult?) -> Void)
}

@MainActor
public enum CartModule {
    public typealias Instance = (viewController: UIViewController, navigationInput: any CartNavigationInput)

    public static func create(
        dependencies: CartBusinessDependencies,
        onEvent: @escaping (CartNavigationOutputEvent) -> Void
    ) -> Instance {
        let coordinator = CartCoordinator(
            composer: CartComposer(dependencies: dependencies),
            onEvent: onEvent
        )
        let nav = UINavigationController()
        nav.navigationBar.prefersLargeTitles = true
        let router = StackRouter(coordinator: coordinator, navigationController: nav)
        return (router.extractRootUI(), coordinator)
    }
}
