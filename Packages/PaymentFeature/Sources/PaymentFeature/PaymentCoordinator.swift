//
//  PaymentCoordinator.swift
//  PaymentFeature
//
//  Created by Любченко Станислав Валерьевич on 19.02.2026.
//

import UIKit
import Core

typealias PaymentPresenterEventHandler = (PaymentPresenter.Event) -> Void

enum PaymentRoute {
    case payment(eventHandler: PaymentPresenterEventHandler)
}

typealias PaymentInlineCoordinator = PaymentCoordinatingLogic

@MainActor
final class PaymentCoordinatingLogic: BaseCoordinator<any StackNavigation, PaymentRoute> {
    init<C: Composing>(
        router: any StackNavigation,
        composer: C,
        onEvent: @escaping (PaymentNavigationOutputEvent) -> Void,
    ) where C.Route == PaymentRoute {
        self.onEvent = onEvent
        super.init(router: router, composer: composer)
    }

    override func start(_ context: CoordinatorStartContext) {
        let paymentItem = composer.makeItem(for: .payment(eventHandler: { [weak self] event in
            self?.handle(event: event)
        }))
        router.push(paymentItem, animated: false, completion: nil)
    }

    // MARK: - Private members

    private let onEvent: (PaymentNavigationOutputEvent) -> Void

    private func handle(event: PaymentPresenter.Event) {
        switch event {
        case .onBackTap:
            onEvent(.cancelled)
        case let .onPaymentCompleted(result):
            onEvent(.completed(result))
        }
    }
}
