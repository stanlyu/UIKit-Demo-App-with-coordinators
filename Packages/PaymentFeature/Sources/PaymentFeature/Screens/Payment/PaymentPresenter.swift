//
//  PaymentPresenter.swift
//  PaymentFeature
//
//  Created by Любченко Станислав Валерьевич on 19.02.2026.
//

import Foundation

@MainActor
protocol PaymentView: AnyObject {
    func setAmountText(_ text: String)
    func setProcessingState(isProcessing: Bool)
}

@MainActor
protocol PaymentViewOutput: AnyObject {
    func viewDidLoad()
    func backButtonDidTap()
    func payButtonDidTap()
}

@MainActor
final class PaymentPresenter: PaymentViewOutput {
    enum Event {
        case onBackTap
        case onPaymentCompleted(PaymentResult)
    }

    weak var view: PaymentView?

    init(interactor: PaymentInteracting, onEvent: @escaping (Event) -> Void) {
        self.interactor = interactor
        self.onEvent = onEvent
    }

    func viewDidLoad() {
        view?.setAmountText(makeAmountText(amount: interactor.amount))
        view?.setProcessingState(isProcessing: interactor.isProcessing)
    }

    func backButtonDidTap() {
        guard interactor.isProcessing == false else { return }
        onEvent(.onBackTap)
    }

    func payButtonDidTap() {
        interactor.processPayment { [weak self] result in
            guard let self else { return }
            view?.setProcessingState(isProcessing: interactor.isProcessing)
            onEvent(.onPaymentCompleted(result))
        }

        view?.setProcessingState(isProcessing: interactor.isProcessing)
    }

    // MARK: - Private members

    private let interactor: PaymentInteracting
    private let onEvent: (Event) -> Void

    private func makeAmountText(amount: Int) -> String {
        let formattedAmount = amount.formatted(
            .number
                .locale(Locale(identifier: "ru_RU"))
                .grouping(.automatic)
        )
        return "\(formattedAmount) ₽"
    }
}
