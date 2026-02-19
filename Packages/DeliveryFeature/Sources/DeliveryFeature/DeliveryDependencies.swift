//
//  DeliveryDependencies.swift
//  DeliveryFeature
//
//  Created by Любченко Станислав Валерьевич on 19.02.2026.
//

import Foundation

public enum PickupPointsManagerEvent {
    case pickupPointSelected(id: Int)
    case pickupPointAddedToFavorites(id: Int)
    case pickupPointRemovedFromFavorites(id: Int)
}

@MainActor
public protocol PickupPointsManaging: AnyObject {
    var availablePickupPoints: [PickupPoint] { get }
    var favoritePickupPoints: [PickupPoint] { get }
    var selectedPickupPoint: PickupPoint? { get }

    func subscribe(_ listener: @escaping (PickupPointsManagerEvent) -> Void)

    func addToFavorites(pickupPointID id: Int)

    @discardableResult
    func selectPickupPoint(pickupPointID id: Int) -> Bool

    func removeFromFavorites(pickupPointID id: Int)
}

public struct DeliveryDependencies {
    let pickupPointsManager: PickupPointsManaging

    public init(pickupPointsManager: PickupPointsManaging) {
        self.pickupPointsManager = pickupPointsManager
    }
}
