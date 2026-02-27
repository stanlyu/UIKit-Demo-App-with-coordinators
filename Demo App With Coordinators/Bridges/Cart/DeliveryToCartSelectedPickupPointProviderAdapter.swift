//
//  DeliveryToCartSelectedPickupPointProviderAdapter.swift
//  Demo App With Coordinators
//
//  Created by Любченко Станислав Валерьевич on 19.02.2026.
//

import CartFeature
import DeliveryFeature

@MainActor
final class DeliveryToCartSelectedPickupPointProviderAdapter: CartSelectedPickupPointProviding {
    var selectedPickupPoint: CartPickupPoint? {
        guard let pickupPoint = pickupPointsManager.selectedPickupPoint else { return nil }
        return CartPickupPoint(id: pickupPoint.id, name: pickupPoint.name)
    }

    init(pickupPointsManager: PickupPointsManaging) {
        self.pickupPointsManager = pickupPointsManager
    }

    func subscribeToSelectedPickupPointChanges(_ listener: @escaping (CartPickupPoint) -> Void) {
        pickupPointsManager.subscribe { [weak self] event in
            guard case .pickupPointSelected = event,
                    let selectedPickupPoint = self?.selectedPickupPoint
            else { return }
            listener(selectedPickupPoint)
        }
    }

    // MARK: - Private members

    private let pickupPointsManager: PickupPointsManaging
}
