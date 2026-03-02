//
//  PaymentComposer.swift
//  PaymentFeature
//
//  Created by Любченко Станислав Валерьевич on 19.02.2026.
//

import UIKit
import Core

typealias PaymentEventHandler = (PaymentPresenter.Event) -> Void

enum PaymentRoute {
    case payment(eventHandler: PaymentEventHandler)
}

@MainActor
protocol PaymentComposing: Composing where Route == PaymentRoute {}

struct PaymentComposer: PaymentComposing {
    func makeViewController(for route: PaymentRoute) -> UIViewController {
        switch route {
        case .payment(let eventHandler):
            let interactor = PaymentInteractor(service: PaymentService())
            let presenter = PaymentPresenter(interactor: interactor, onEvent: eventHandler)
            let viewController = PaymentViewController(viewOutput: presenter)
            presenter.view = viewController
            return viewController
        }
    }
}
