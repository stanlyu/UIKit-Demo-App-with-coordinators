//
//  CartComposer.swift
//  CartFeature
//
//  Created by Любченко Станислав Валерьевич on 22.12.2025.
//

import UIKit

typealias CartEventHandler = (CartPresenter.Event) -> Void

@MainActor
protocol CartComposing {
    func makeCartViewController(with eventHandler: @escaping CartEventHandler) -> UINavigationController

    func makePlaceOrderViewController(orderID: Int) -> UIViewController
}

struct CartComposer: CartComposing {
    func makeCartViewController(with eventHandler: @escaping CartEventHandler) -> UINavigationController {
        let service = CartService()
        let interactor = CartInteractor(service: service)
        let presenter = CartPresenter(interactor: interactor, onEvent: eventHandler)
        let cartViewController = CartViewController()
        presenter.view = cartViewController
        cartViewController.viewOutput = presenter
        let navigationController = UINavigationController(rootViewController: cartViewController)
        navigationController.navigationBar.prefersLargeTitles = true
        return navigationController
    }

    func makePlaceOrderViewController(orderID: Int) -> UIViewController {
        #warning("TODO: Implement makePlaceOrderViewController in CartComposer")
        return UIViewController()
    }
}
