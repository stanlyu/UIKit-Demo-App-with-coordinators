//
//  PickupPointsService.swift
//  DeliveryFeature
//
//  Created by Любченко Станислав Валерьевич on 22.12.2025.
//

protocol PickupPointsServicing: Sendable {
    @concurrent func fetchPickupPointsData() async
}

struct PickupPointsService: PickupPointsServicing {
    @concurrent func fetchPickupPointsData() async {
        // Эмитируем загрузку данных
        try? await Task.sleep(nanoseconds: 2_000_000_000)
    }
}
