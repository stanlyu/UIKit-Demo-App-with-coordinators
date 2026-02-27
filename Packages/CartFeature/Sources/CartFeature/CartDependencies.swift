//
//  CartDependencies.swift
//  CartFeature
//
//  Created by Любченко Станислав Валерьевич on 19.02.2026.
//

import Foundation
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
public protocol CartExternalModulesFactory: AnyObject {
    func makePickupPointsViewController() -> UIViewController
    func makePaymentViewController(onComplete: @escaping (CartPaymentResult?) -> Void) -> UIViewController
}

public struct CartDependencies {
    let selectedPickupPointProvider: CartSelectedPickupPointProviding
    public private(set) weak var externalModulesFactory: (any CartExternalModulesFactory)?

    public init(
        selectedPickupPointProvider: CartSelectedPickupPointProviding,
        externalModulesFactory: CartExternalModulesFactory
    ) {
        self.selectedPickupPointProvider = selectedPickupPointProvider
        self.externalModulesFactory = externalModulesFactory
    }
}
