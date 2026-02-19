//
//  PaymentInteractor.swift
//  PaymentFeature
//
//  Created by Любченко Станислав Валерьевич on 19.02.2026.
//

import Foundation

@MainActor
protocol PaymentInteracting: AnyObject {
    var amount: Int { get }
    var isProcessing: Bool { get }
    func processPayment(completion: @escaping (PaymentResult) -> Void)
}

@MainActor
final class PaymentInteractor: PaymentInteracting {
    let amount: Int
    private(set) var isProcessing = false

    init(service: PaymentServicing) {
        self.service = service
        self.amount = Int.random(in: 100...100_000)
    }

    func processPayment(completion: @escaping (PaymentResult) -> Void) {
        guard isProcessing == false else { return }
        isProcessing = true

        Task {
            let result = await service.processPayment(amount: amount)
            isProcessing = false
            completion(result)
        }
    }

    // MARK: - Private members

    private let service: PaymentServicing
}
