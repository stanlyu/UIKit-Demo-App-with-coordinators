//
//  PaymentCoordinator.swift
//  PaymentFeature
//
//  Created by Любченко Станислав Валерьевич on 19.02.2026.
//

import UIKit
import Core

typealias PaymentInlineCoordinator = PaymentCoordinatingLogic<InlineRouter>

@MainActor
final class PaymentCoordinatingLogic<Router: StackRouting>: Coordinator<Router, PaymentRoute> {
    init<C: PaymentComposing>(composer: C, eventHandler: @escaping (PaymentEvent) -> Void) {
        self.eventHandler = eventHandler
        super.init(composer: composer)
    }

    override func start(_ capability: StartCapability) {
        let paymentItem = composer.makeItem(for: .payment(eventHandler: { [weak self] event in
            self?.handle(event: event)
        }))
        router?.push(paymentItem, animated: false, completion: nil)
    }

    // MARK: - Private members

    private let eventHandler: (PaymentEvent) -> Void

    private func handle(event: PaymentPresenter.Event) {
        switch event {
        case .onBackTap:
            eventHandler(.cancelled)
        case let .onPaymentCompleted(result):
            eventHandler(.completed(result))
        }
    }
}
