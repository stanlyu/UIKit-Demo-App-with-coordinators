//
//  PickupPointsInteractor.swift
//  DeliveryFeature
//
//  Created by Любченко Станислав Валерьевич on 22.12.2025.
//

import Foundation

struct PickupPointsState {
    let activePickupPoint: PickupPoint?
    let favoritePickupPoints: [PickupPoint]
    let selectedFavoritePickupPointID: Int?
    let canConfirmSelection: Bool
}

@MainActor
protocol PickupPointsInteracting: AnyObject {
    func activate()
    func selectFavoritePickupPoint(id: Int)
    func confirmSelectedPickupPoint()
    func removeFromFavorites(pickupPointID id: Int)
    func subscribeToStateChanges(_ listener: @escaping (PickupPointsState) -> Void)
}

@MainActor
final class PickupPointsInteractor: PickupPointsInteracting {
    init(manager: PickupPointsManaging) {
        self.manager = manager
        refreshFromManager(resetSelection: true)
        subscribeToManagerEvents()
    }

    func activate() {
        refreshFromManager(resetSelection: true)
        notifyStateChanges()
    }

    func selectFavoritePickupPoint(id: Int) {
        guard favoritePickupPointIDs.contains(id), selectedFavoritePickupPointID != id else { return }

        selectedFavoritePickupPointID = id
        notifyStateChanges()
    }

    func confirmSelectedPickupPoint() {
        guard let selectedFavoritePickupPointID else { return }

        ignoreManagerEvents = true
        defer {
            ignoreManagerEvents = false
        }

        _ = manager.selectPickupPoint(pickupPointID: selectedFavoritePickupPointID)
        refreshFromManager(resetSelection: true)
        notifyStateChanges()
    }

    func removeFromFavorites(pickupPointID id: Int) {
        guard favoritePickupPointIDs.contains(id) else { return }

        ignoreManagerEvents = true
        defer {
            ignoreManagerEvents = false
        }

        manager.removeFromFavorites(pickupPointID: id)
        refreshFromManager(resetSelection: false)
        notifyStateChanges()
    }

    func subscribeToStateChanges(_ listener: @escaping (PickupPointsState) -> Void) {
        stateChangesListener = listener
    }

    // MARK: - Private members

    private let manager: PickupPointsManaging

    private var stateChangesListener: ((PickupPointsState) -> Void)?
    private var ignoreManagerEvents = false

    private var activePickupPoint: PickupPoint?
    private var favoritePickupPoints: [PickupPoint] = []
    private var favoritePickupPointIDs = Set<Int>()
    private var selectedFavoritePickupPointID: Int?

    private func subscribeToManagerEvents() {
        manager.subscribe { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                guard self.ignoreManagerEvents == false else { return }

                self.refreshFromManager(resetSelection: false)
                self.notifyStateChanges()
            }
        }
    }

    private func refreshFromManager(resetSelection: Bool) {
        activePickupPoint = manager.selectedPickupPoint
        favoritePickupPoints = manager.favoritePickupPoints
        favoritePickupPointIDs = Set(favoritePickupPoints.map(\.id))

        if resetSelection {
            selectedFavoritePickupPointID = nil
        } else if let selectedFavoritePickupPointID,
                  !favoritePickupPointIDs.contains(selectedFavoritePickupPointID) {
            self.selectedFavoritePickupPointID = nil
        }
    }

    private func notifyStateChanges() {
        stateChangesListener?(makeState())
    }

    private func makeState() -> PickupPointsState {
        PickupPointsState(
            activePickupPoint: activePickupPoint,
            favoritePickupPoints: favoritePickupPoints,
            selectedFavoritePickupPointID: selectedFavoritePickupPointID,
            canConfirmSelection: selectedFavoritePickupPointID != nil
        )
    }
}
