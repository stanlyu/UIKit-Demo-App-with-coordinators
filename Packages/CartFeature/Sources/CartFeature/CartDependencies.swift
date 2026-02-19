//
//  CartDependencies.swift
//  CartFeature
//
//  Created by Любченко Станислав Валерьевич on 19.02.2026.
//

import Foundation

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

public struct CartDependencies {
    let selectedPickupPointProvider: CartSelectedPickupPointProviding

    public init(selectedPickupPointProvider: CartSelectedPickupPointProviding) {
        self.selectedPickupPointProvider = selectedPickupPointProvider
    }
}
