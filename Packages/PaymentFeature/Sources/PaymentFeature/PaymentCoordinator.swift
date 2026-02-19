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
final class PaymentCoordinatingLogic<Router: StackRouting>: Coordinator<Router> {
    init(composer: PaymentComposing, eventHandler: @escaping (PaymentEvent) -> Void) {
        self.composer = composer
        self.eventHandler = eventHandler
        super.init()
    }

    override func start() {
        let paymentViewController = composer.makePaymentViewController { [weak self] event in
            self?.handle(event: event)
        }
        router?.push(paymentViewController, animated: false, completion: nil)
    }

    // MARK: - Private members

    private let composer: PaymentComposing
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
