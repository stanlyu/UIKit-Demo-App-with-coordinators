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

typealias PaymentInlineCoordinator = PaymentCoordinatingLogic<InlineRouter>

@MainActor
final class PaymentCoordinatingLogic<Router: StackRouting>: Coordinator<Router, PaymentRoute> {
    init(
        onEvent: @escaping (PaymentNavigationOutputEvent) -> Void,
        buildBlock: @MainActor @Sendable @escaping (PaymentRoute) -> UIViewController
    ) {
        self.onEvent = onEvent
        super.init(buildBlock: buildBlock)
    }

    override func start(_ capability: StartCapability) {
        let paymentItem = composer.makeItem(for: .payment(eventHandler: { [weak self] event in
            self?.handle(event: event)
        }))
        router?.push(paymentItem, animated: false, completion: nil)
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
