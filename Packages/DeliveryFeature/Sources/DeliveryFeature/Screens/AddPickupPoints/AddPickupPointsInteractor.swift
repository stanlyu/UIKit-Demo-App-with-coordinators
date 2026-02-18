//
//  AddPickupPointsInteractor.swift
//  DeliveryFeature
//
//  Created by Любченко Станислав Валерьевич on 16.02.2026.
//

import Foundation

struct AddPickupPointsState {
    let pickupPoints: [PickupPoint]
    let selectedPickupPointIDs: Set<Int>
    let canApplyChanges: Bool
}

@MainActor
protocol AddPickupPointsInteracting: AnyObject {
    func activate()
    func toggleSelection(pickupPointID id: Int)
    func applyChanges()
    func subscribeToStateChanges(_ listener: @escaping (AddPickupPointsState) -> Void)
}

@MainActor
final class AddPickupPointsInteractor: AddPickupPointsInteracting {
    init(manager: PickupPointsManaging) {
        self.manager = manager
        refreshFromManager(resetSelection: true)
        subscribeToManagerEvents()
    }

    func activate() {
        refreshFromManager(resetSelection: true)
        notifyStateChange()
    }

    func toggleSelection(pickupPointID id: Int) {
        guard remainingPickupPointIDs.contains(id) else { return }

        if selectedPickupPointIDs.contains(id) {
            selectedPickupPointIDs.remove(id)
        } else {
            selectedPickupPointIDs.insert(id)
        }

        notifyStateChange()
    }

    func applyChanges() {
        let idsToAdd = selectedPickupPointIDs.intersection(remainingPickupPointIDs)
        guard idsToAdd.isEmpty == false else { return }

        ignoreManagerEvents = true
        defer {
            ignoreManagerEvents = false
        }

        for id in idsToAdd {
            manager.addToFavorites(pickupPointID: id)
        }

        refreshFromManager(resetSelection: true)
        notifyStateChange()
    }

    func subscribeToStateChanges(_ listener: @escaping (AddPickupPointsState) -> Void) {
        stateChangesListener = listener
    }

    // MARK: - Private members

    private let manager: PickupPointsManaging

    private var stateChangesListener: ((AddPickupPointsState) -> Void)?
    private var ignoreManagerEvents = false

    private var remainingPickupPoints: [PickupPoint] = []
    private var remainingPickupPointIDs = Set<Int>()
    private var selectedPickupPointIDs = Set<Int>()

    private func subscribeToManagerEvents() {
        manager.subscribe { [weak self] event in
            guard let self else { return }
            Task { @MainActor in
                guard self.ignoreManagerEvents == false else { return }

                switch event {
                case .pickupPointAddedToFavorites, .pickupPointRemovedFromFavorites:
                    let remainingListDidChange = self.refreshFromManager(resetSelection: false)
                    if remainingListDidChange {
                        self.notifyStateChange()
                    }
                case .pickupPointSelected:
                    break
                }
            }
        }
    }

    @discardableResult
    private func refreshFromManager(resetSelection: Bool) -> Bool {
        let previousRemainingIDs = remainingPickupPointIDs

        let allPickupPoints = manager.availablePickupPoints
        let favoritePickupPointIDs = Set(manager.favoritePickupPoints.map(\.id))
        let activePickupPointID = manager.selectedPickupPoint?.id

        remainingPickupPoints = allPickupPoints.filter { pickupPoint in
            guard favoritePickupPointIDs.contains(pickupPoint.id) == false else { return false }
            guard activePickupPointID != pickupPoint.id else { return false }
            return true
        }
        remainingPickupPointIDs = Set(remainingPickupPoints.map(\.id))

        if resetSelection {
            selectedPickupPointIDs.removeAll()
        } else {
            selectedPickupPointIDs = selectedPickupPointIDs.intersection(remainingPickupPointIDs)
        }

        return previousRemainingIDs != remainingPickupPointIDs
    }

    private func notifyStateChange() {
        stateChangesListener?(makeState())
    }

    private func makeState() -> AddPickupPointsState {
        AddPickupPointsState(
            pickupPoints: remainingPickupPoints,
            selectedPickupPointIDs: selectedPickupPointIDs,
            canApplyChanges: selectedPickupPointIDs.isEmpty == false
        )
    }
}
