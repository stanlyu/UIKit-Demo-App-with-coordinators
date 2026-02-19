//
//  CartComposer.swift
//  CartFeature
//
//  Created by Любченко Станислав Валерьевич on 22.12.2025.
//

import UIKit

typealias CartEventHandler = (CartPresenter.Event) -> Void
typealias PlaceOrderEventHandler = (PlaceOrderPresenter.Event) -> Void
typealias OrderConfirmationEventHandler = (OrderConfirmationPresenter.Event) -> Void

@MainActor
protocol CartComposing {
    func makeCartViewController(with eventHandler: @escaping CartEventHandler) -> UIViewController

    func makePlaceOrderViewController(
        with orderID: Int,
        eventHandler: @escaping PlaceOrderEventHandler
    ) -> UIViewController

    func makeOrderConfirmationViewController(
        paymentResult: CartPaymentResult,
        with eventHandler: @escaping OrderConfirmationEventHandler
    ) -> UIViewController
}

struct CartComposer: CartComposing {
    init(dependencies: CartDependencies) {
        self.dependencies = dependencies
    }

    func makeCartViewController(with eventHandler: @escaping CartEventHandler) -> UIViewController {
        let service = CartService()
        let interactor = CartInteractor(service: service)
        let presenter = CartPresenter(interactor: interactor, onEvent: eventHandler)
        let cartViewController = CartViewController()
        presenter.view = cartViewController
        cartViewController.viewOutput = presenter
        return cartViewController
    }

    func makePlaceOrderViewController(
        with orderID: Int,
        eventHandler: @escaping PlaceOrderEventHandler
    ) -> UIViewController {
        let service = PlaceOrderService()
        let interactor = PlaceOrderInteractor(
            orderID: orderID,
            service: service,
            selectedPickupPointProvider: dependencies.selectedPickupPointProvider
        )
        let presenter = PlaceOrderPresenter(interactor: interactor, onEvent: eventHandler)
        let viewController = PlaceOrderViewController()
        presenter.view = viewController
        viewController.viewOutput = presenter
//        viewController.hidesBottomBarWhenPushed = true
        return viewController
    }

    func makeOrderConfirmationViewController(
        paymentResult: CartPaymentResult,
        with eventHandler: @escaping OrderConfirmationEventHandler
    ) -> UIViewController {
        let presenter = OrderConfirmationPresenter(paymentResult: paymentResult, onEvent: eventHandler)
        let viewController = OrderConfirmationViewController()
        presenter.view = viewController
        viewController.viewOutput = presenter
        return viewController
    }

    // MARK: - Private members

    private let dependencies: CartDependencies
}
