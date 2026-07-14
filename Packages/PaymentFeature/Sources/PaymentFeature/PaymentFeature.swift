//
//  PaymentFeature.swift
//  PaymentFeature
//
//  Created by Любченко Станислав Валерьевич on 19.02.2026.
//

import UIKit
import Core

public enum PaymentNavigationOutputEvent {
    case completed(PaymentResult)
    case cancelled
}

@MainActor
public enum PaymentModule {
    public static func create(
        onEvent: @escaping (PaymentNavigationOutputEvent) -> Void
    ) -> UIViewController {
        Flow.inline(
            composer: InlineComposer<PaymentRoute> { route in
                switch route {
                case .payment(let handler):
                    let interactor = PaymentInteractor(service: PaymentService())
                    let presenter = PaymentPresenter(interactor: interactor, onEvent: handler)
                    let viewController = PaymentViewController(viewOutput: presenter)
                    presenter.view = viewController
                    return viewController
                }
            }
        ) { router, composer in
            PaymentInlineCoordinator(
                router: router,
                composer: composer,
                onEvent: onEvent
            )
        }.viewController
    }
}
