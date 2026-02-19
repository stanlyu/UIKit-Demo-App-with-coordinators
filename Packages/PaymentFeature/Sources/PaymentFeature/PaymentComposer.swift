//
//  PaymentComposer.swift
//  PaymentFeature
//
//  Created by Любченко Станислав Валерьевич on 19.02.2026.
//

import UIKit

typealias PaymentEventHandler = (PaymentPresenter.Event) -> Void

@MainActor
protocol PaymentComposing {
    func makePaymentViewController(with eventHandler: @escaping PaymentEventHandler) -> UIViewController
}

struct PaymentComposer: PaymentComposing {
    func makePaymentViewController(with eventHandler: @escaping PaymentEventHandler) -> UIViewController {
        let interactor = PaymentInteractor(service: PaymentService())
        let presenter = PaymentPresenter(interactor: interactor, onEvent: eventHandler)
        let viewController = PaymentViewController(viewOutput: presenter)
        presenter.view = viewController
        return viewController
    }
}
