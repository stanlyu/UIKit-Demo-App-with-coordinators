//
//  MainTabsComposer+PaymentToCartTypeConverting.swift
//  Demo App With Coordinators
//
//  Created by Любченко Станислав Валерьевич on 19.02.2026.
//

import CartFeature
import PaymentFeature

extension MainTabsComposer: PaymentToCartTypeConverting {
    func makeCartPaymentResult(from paymentResult: PaymentResult) -> CartPaymentResult {
        switch paymentResult {
        case let .success(amount):
            return .success(amount: amount)
        case let .failure(amount, error):
            return .failure(amount: amount, error: makeCartPaymentError(from: error))
        }
    }

    func makeCartPaymentError(from paymentError: PaymentError) -> CartPaymentError {
        switch paymentError {
        case .insufficientFunds:
            return .insufficientFunds
        case .cardExpired:
            return .cardExpired
        case .bankDeclined:
            return .bankDeclined
        case .networkUnavailable:
            return .networkUnavailable
        case .processingTimeout:
            return .processingTimeout
        }
    }
}
