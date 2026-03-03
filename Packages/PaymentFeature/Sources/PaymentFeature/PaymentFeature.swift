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
    let coordinator = PaymentInlineCoordinator(
        eventHandler: eventHandler,
        buildBlock: { route in
            switch route {
            case .payment(let handler):
                let interactor = PaymentInteractor(service: PaymentService())
                let presenter = PaymentPresenter(interactor: interactor, onEvent: handler)
                let viewController = PaymentViewController(viewOutput: presenter)
                presenter.view = viewController
                return viewController
            }
        }
    )
    let router = InlineRouter(coordinator: coordinator)
    return router.extractRootUI()
}
