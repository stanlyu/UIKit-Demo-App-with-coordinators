//
//  MainTabsComposer+CartExternalModulesFactory.swift
//  Demo App With Coordinators
//
//  Created by Любченко Станислав Валерьевич on 27.02.2026.
//

import UIKit
import CartFeature
import PaymentFeature

@MainActor
extension MainTabsComposer: CartExternalModulesFactory {
    func makePickupPointsViewController() -> UIViewController {
        makePickupPointsViewController(embeddedInNavigationStack: false, eventHandler: nil)
    }

    func makePaymentViewController(onComplete: @escaping (CartPaymentResult?) -> Void) -> UIViewController {
        PaymentFeature.paymentViewController { [weak self] event in
            guard let self else { return }

            switch event {
            case .cancelled:
                onComplete(nil)
            case let .completed(paymentResult):
                onComplete(makeCartPaymentResult(from: paymentResult))
            }
        }
    }
}
