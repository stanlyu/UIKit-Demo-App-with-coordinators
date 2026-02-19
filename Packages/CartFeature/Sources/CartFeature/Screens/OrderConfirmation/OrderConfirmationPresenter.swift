//
//  OrderConfirmationPresenter.swift
//  CartFeature
//
//  Created by Любченко Станислав Валерьевич on 22.12.2025.
//

import UIKit

struct OrderConfirmationViewState {
    let message: String
    let messageColor: UIColor
}

@MainActor
protocol OrderConfirmationView: AnyObject {
    func render(_ state: OrderConfirmationViewState)
}

@MainActor
protocol OrderConfirmationViewOutput: AnyObject {
    func viewDidLoad()
    func returnButtonDidTap()
}

@MainActor
final class OrderConfirmationPresenter {
    enum Event {
        case onReturnTap
    }

    weak var view: OrderConfirmationView?

    init(paymentResult: CartPaymentResult, onEvent: @escaping (Event) -> Void) {
        self.paymentResult = paymentResult
        self.onEvent = onEvent
    }

    // MARK: - Private properties

    private let paymentResult: CartPaymentResult
    private let onEvent: (Event) -> Void

    private func makeViewState() -> OrderConfirmationViewState {
        switch paymentResult {
        case let .success(amount):
            return OrderConfirmationViewState(
                message: "Оплата выполнена успешно\nСумма: \(formattedAmount(amount)) ₽",
                messageColor: UIColor(red: 0.15, green: 0.30, blue: 0.16, alpha: 1.0)
            )
        case let .failure(amount, error):
            return OrderConfirmationViewState(
                message: message(for: error, amount: amount),
                messageColor: color(for: error)
            )
        }
    }

    private func message(for error: CartPaymentError, amount: Int) -> String {
        let amountText = formattedAmount(amount)

        switch error {
        case .insufficientFunds:
            return "Оплата не прошла: недостаточно средств на карте\nСумма: \(amountText) ₽"
        case .cardExpired:
            return "Оплата не прошла: срок действия карты истек\nСумма: \(amountText) ₽"
        case .bankDeclined:
            return "Оплата не прошла: банк отклонил операцию\nСумма: \(amountText) ₽"
        case .networkUnavailable:
            return "Оплата не прошла: отсутствует соединение с сетью\nСумма: \(amountText) ₽"
        case .processingTimeout:
            return "Оплата не прошла: превышено время ожидания ответа сервиса\nСумма: \(amountText) ₽"
        }
    }

    private func color(for error: CartPaymentError) -> UIColor {
        switch error {
        case .insufficientFunds, .cardExpired, .bankDeclined:
            return .systemRed
        case .networkUnavailable, .processingTimeout:
            return .systemOrange
        }
    }

    private func formattedAmount(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
}

extension OrderConfirmationPresenter: OrderConfirmationViewOutput {
    func viewDidLoad() {
        view?.render(makeViewState())
    }

    func returnButtonDidTap() {
        onEvent(.onReturnTap)
    }
}
