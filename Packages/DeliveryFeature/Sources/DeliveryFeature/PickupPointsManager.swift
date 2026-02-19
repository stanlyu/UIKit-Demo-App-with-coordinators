//
//  PickupPointsManager.swift
//  DeliveryFeature
//
//  Created by Любченко Станислав Валерьевич on 16.02.2026.
//

import Foundation

@MainActor
final class PickupPointsManager: PickupPointsManaging {
    var availablePickupPoints: [PickupPoint] {
        Self.generatedPickupPoints
    }

    var favoritePickupPoints: [PickupPoint] {
        state.favoriteIDs.compactMap { Self.generatedPickupPointsByID[$0] }
    }

    var selectedPickupPoint: PickupPoint? {
        guard let selectedID = state.selectedID else { return nil }
        return Self.generatedPickupPointsByID[selectedID]
    }

    init(
        userDefaults: UserDefaults = .standard,
        storageKey: String = "DeliveryFeature.PickupPointsManager.State"
    ) {
        self.userDefaults = userDefaults
        self.storageKey = storageKey

        if let data = userDefaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(PersistentState.self, from: data) {
            state = Self.sanitize(decoded)
        } else {
            state = PersistentState()
        }
    }

    func subscribe(_ listener: @escaping (PickupPointsManagerEvent) -> Void) {
        eventListeners.append(listener)
    }

    func addToFavorites(pickupPointID id: Int) {
        guard Self.generatedPickupPointsByID[id] != nil else { return }
        guard state.selectedID != id else { return }
        guard state.favoriteIDs.contains(id) == false else { return }

        state.favoriteIDs.append(id)
        persistState()
        notify(.pickupPointAddedToFavorites(id: id))
    }

    @discardableResult
    func selectPickupPoint(pickupPointID id: Int) -> Bool {
        guard state.favoriteIDs.contains(id) else { return false }

        state.favoriteIDs.removeAll { $0 == id }

        if let oldSelectedID = state.selectedID,
           oldSelectedID != id,
           Self.generatedPickupPointsByID[oldSelectedID] != nil,
           state.favoriteIDs.contains(oldSelectedID) == false {
            state.favoriteIDs.append(oldSelectedID)
        }

        state.selectedID = id
        persistState()
        notify(.pickupPointSelected(id: id))
        return true
    }

    func removeFromFavorites(pickupPointID id: Int) {
        let beforeCount = state.favoriteIDs.count
        state.favoriteIDs.removeAll { $0 == id }

        if state.favoriteIDs.count != beforeCount {
            persistState()
            notify(.pickupPointRemovedFromFavorites(id: id))
        }
    }

    // MARK: - Private members

    private struct PersistentState: Codable {
        var favoriteIDs: [Int] = []
        var selectedID: Int?
    }

    private static let generatedPickupPoints: [PickupPoint] = (1...20).map {
        PickupPoint(id: $0, name: "ПВЗ \($0)")
    }

    private static let generatedPickupPointsByID: [Int: PickupPoint] = Dictionary(
        uniqueKeysWithValues: generatedPickupPoints.map { ($0.id, $0) }
    )

    private let userDefaults: UserDefaults
    private let storageKey: String
    private var state: PersistentState
    private var eventListeners: [(PickupPointsManagerEvent) -> Void] = []

    private func persistState() {
        guard let data = try? JSONEncoder().encode(state) else { return }
        userDefaults.set(data, forKey: storageKey)
    }

    private func notify(_ event: PickupPointsManagerEvent) {
        eventListeners.forEach { listener in
            listener(event)
        }
    }

    private static func sanitize(_ state: PersistentState) -> PersistentState {
        var selectedID = state.selectedID

        if let currentSelectedID = selectedID,
           Self.generatedPickupPointsByID[currentSelectedID] == nil {
            selectedID = nil
        }

        var uniqueIDs = Set<Int>()
        let favoriteIDs = state.favoriteIDs.filter { id in
            guard Self.generatedPickupPointsByID[id] != nil else { return false }
            guard selectedID != id else { return false }
            return uniqueIDs.insert(id).inserted
        }

        return PersistentState(favoriteIDs: favoriteIDs, selectedID: selectedID)
    }
}
