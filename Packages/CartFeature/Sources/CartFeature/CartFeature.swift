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

public enum CartNavigationOutputEvent {}

@MainActor
public enum CartModule {
    public typealias Instance = (viewController: UIViewController, navigationInput: any CartNavigationInput)

    public static func create(
        dependencies: CartBusinessDependencies,
        onEvent: @escaping (CartNavigationOutputEvent) -> Void
    ) -> Instance {
        let flow = FlowBuilder.stack(
            makeNavigationController: {
                let nav = UINavigationController()
                nav.navigationBar.prefersLargeTitles = true
                return nav
            },
            composer: CartComposer(dependencies: dependencies)
        ) { router, composer in
            CartCoordinator(
                router: router,
                composer: composer,
                onEvent: onEvent
            )
        }
        return (flow.viewController, flow.coordinator)
    }
}
