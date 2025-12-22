//
//  PickupPointsInteractor.swift
//  DeliveryFeature
//
//  Created by Любченко Станислав Валерьевич on 22.12.2025.
//

@MainActor
protocol PickupPointsInteracting: AnyObject {
    func fetchData(completion: @escaping () -> Void)
}

final class PickupPointsInteractor {

    init(service: PickupPointsServicing) {
        self.service = service
    }

    // MARK: - Private properties

    private let service: PickupPointsServicing
}

extension PickupPointsInteractor: PickupPointsInteracting {
    func fetchData(completion: @escaping () -> Void) {
        Task {
            await service.fetchPickupPointsData()
            completion()
        }
    }
}
