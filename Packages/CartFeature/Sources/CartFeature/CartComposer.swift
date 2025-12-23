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
        with eventHandler: @escaping OrderConfirmationEventHandler
    ) -> UIViewController
}

struct CartComposer: CartComposing {
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
        let interactor = PlaceOrderInteractor(orderID: orderID, service: service)
        let presenter = PlaceOrderPresenter(interactor: interactor, onEvent: eventHandler)
        let viewController = PlaceOrderViewController()
        presenter.view = viewController
        viewController.viewOutput = presenter
        viewController.hidesBottomBarWhenPushed = true
        return viewController
    }

    func makeOrderConfirmationViewController(
        with eventHandler: @escaping OrderConfirmationEventHandler
    ) -> UIViewController {
        let presenter = OrderConfirmationPresenter(onEvent: eventHandler)
        let viewController = OrderConfirmationViewController()
        viewController.viewOutput = presenter
        return viewController
    }
}
