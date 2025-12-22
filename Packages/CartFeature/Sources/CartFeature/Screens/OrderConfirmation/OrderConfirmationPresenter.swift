//
//  OrderConfirmationPresenter.swift
//  CartFeature
//
//  Created by Любченко Станислав Валерьевич on 22.12.2025.
//

@MainActor
protocol OrderConfirmationViewOutput: AnyObject {
    func returnButtonDidTap()
}

final class OrderConfirmationPresenter {
    enum Event {
        case onReturnTap
    }

    init(onEvent: @escaping (Event) -> Void) {
        self.onEvent = onEvent
    }

    // MARK: - Private properties

    private let onEvent: (Event) -> Void
}

extension OrderConfirmationPresenter: OrderConfirmationViewOutput {
    func returnButtonDidTap() {
        onEvent(.onReturnTap)
    }
}
