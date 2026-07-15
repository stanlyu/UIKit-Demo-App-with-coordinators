//
//  CartDependencies.swift
//  CartFeature
//
//  Created by Любченко Станислав Валерьевич on 19.02.2026.
//

import UIKit

public struct CartPickupPoint: Equatable, Sendable {
    public let id: Int
    public let name: String

    public init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}

@MainActor
public protocol CartSelectedPickupPointProviding: AnyObject {
    var selectedPickupPoint: CartPickupPoint? { get }
    func subscribeToSelectedPickupPointChanges(_ listener: @escaping (CartPickupPoint) -> Void)
}

@MainActor
public protocol CartExternalScreensProvider: AnyObject {
    func makePickupPointsViewController(onClose: @escaping () -> Void) -> UIViewController
    func makePaymentViewController(onComplete: @escaping (CartPaymentResult?) -> Void) -> UIViewController
}

@MainActor
public struct CartBusinessDependencies {
    let selectedPickupPointProvider: CartSelectedPickupPointProviding
    public let externalScreensProvider: any CartExternalScreensProvider

    public init(
        selectedPickupPointProvider: CartSelectedPickupPointProviding,
        externalScreensProvider: any CartExternalScreensProvider
    ) {
        self.selectedPickupPointProvider = selectedPickupPointProvider
        self.externalScreensProvider = externalScreensProvider
    }
}
