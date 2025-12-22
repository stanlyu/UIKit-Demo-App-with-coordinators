//
//  AddPickupPointsPresenter.swift
//  DeliveryFeature
//
//  Created by Любченко Станислав Валерьевич on 22.12.2025.
//

@MainActor
protocol AddPickupPointsViewOutput: AnyObject {
    func backButtonDidTap()
}

final class AddPickupPointsPresenter: AddPickupPointsViewOutput {
    enum Event {
        case onBackTap
    }

    init(onEvent: @escaping (Event) -> Void) {
        self.onEvent = onEvent
    }
    
    
    func backButtonDidTap() {
        onEvent(.onBackTap)
    }

    // MARK: - Private properties

    private let onEvent: (Event) -> Void
}
