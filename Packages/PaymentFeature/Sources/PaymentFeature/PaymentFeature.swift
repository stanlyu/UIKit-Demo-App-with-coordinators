//
//  PaymentFeature.swift
//  PaymentFeature
//
//  Created by Любченко Станислав Валерьевич on 19.02.2026.
//

import UIKit
import Core

public enum PaymentEvent {
    case completed(PaymentResult)
    case cancelled
}

@MainActor
public func paymentViewController(with eventHandler: @escaping (PaymentEvent) -> Void) -> UIViewController {
    let coordinator = PaymentInlineCoordinator(composer: PaymentComposer(), eventHandler: eventHandler)
    let router = InlineRouter(coordinator: coordinator)
    return router
}
