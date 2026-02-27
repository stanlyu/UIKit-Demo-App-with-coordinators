//
//  PaymentToCartTypeConverting.swift
//  Demo App With Coordinators
//
//  Created by Любченко Станислав Валерьевич on 19.02.2026.
//

import CartFeature
import PaymentFeature

@MainActor
protocol PaymentToCartTypeConverting {
    func makeCartPaymentResult(from paymentResult: PaymentResult) -> CartPaymentResult
    func makeCartPaymentError(from paymentError: PaymentError) -> CartPaymentError
}
