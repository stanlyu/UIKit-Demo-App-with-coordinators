//
//  PaymentResult.swift
//  PaymentFeature
//
//  Created by Любченко Станислав Валерьевич on 19.02.2026.
//

import Foundation

public enum PaymentError: CaseIterable, Sendable {
    case insufficientFunds
    case cardExpired
    case bankDeclined
    case networkUnavailable
    case processingTimeout
}

public enum PaymentResult: Sendable {
    case success(amount: Int)
    case failure(amount: Int, error: PaymentError)
}
