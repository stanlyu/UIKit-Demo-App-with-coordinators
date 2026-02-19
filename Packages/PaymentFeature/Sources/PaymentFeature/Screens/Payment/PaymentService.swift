//
//  PaymentService.swift
//  PaymentFeature
//
//  Created by Любченко Станислав Валерьевич on 19.02.2026.
//

import Foundation

protocol PaymentServicing: Sendable {
    @concurrent func processPayment(amount: Int) async -> PaymentResult
}

struct PaymentService: PaymentServicing {
    @concurrent
    func processPayment(amount: Int) async -> PaymentResult {
        let delay = UInt64.random(in: 2_000_000_000...20_000_000_000)
        try? await Task.sleep(nanoseconds: delay)

        let isSuccess = Int.random(in: 0...99) < 65
        if isSuccess {
            return .success(amount: amount)
        }

        let error = PaymentError.allCases.randomElement() ?? .bankDeclined
        return .failure(amount: amount, error: error)
    }
}
