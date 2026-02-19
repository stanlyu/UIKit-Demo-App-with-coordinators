//
//  MainTabsComposer.swift
//  Demo App With Coordinators
//
//  Created by Любченко Станислав Валерьевич on 18.12.2025.
//

import UIKit
import HomeFeature
import CartFeature
import DeliveryFeature
import PaymentFeature

@MainActor
protocol MainTabsComposing: PaymentToCartTypeConverting {
    func makeHomeViewController(with eventHandler: @escaping (HomeEvent) -> Void) -> UIViewController
    func makeCartViewController(with eventHandler: @escaping (CartEvent) -> Void) -> CartModule
    func makePickupPointsViewController(embeddedInNavigationStack: Bool) -> UIViewController
    func makePaymentViewController(with eventHandler: @escaping (PaymentEvent) -> Void) -> UIViewController
}

final class MainTabsComposer: MainTabsComposing {
    func makeHomeViewController(with eventHandler: @escaping (HomeEvent) -> Void) -> UIViewController {
        let homeViewController = homeViewController(with: eventHandler)
        homeViewController.tabBarItem = UITabBarItem(
            title: "Главная",
            image: nil,
            selectedImage: nil
        )
        return homeViewController
    }

    func makeCartViewController(with eventHandler: @escaping (CartEvent) -> Void) -> CartModule {
        let cartModule = cartModule(
            with: eventHandler,
            dependencies: CartDependencies(
                selectedPickupPointProvider: deliveryToCartSelectedPickupPointProvider
            )
        )
        cartModule.viewController.tabBarItem = UITabBarItem(
            title: "Корзина",
            image: nil,
            selectedImage: nil
        )
        return cartModule
    }

    func makePickupPointsViewController(embeddedInNavigationStack: Bool) -> UIViewController {
        DeliveryFeature.pickupPointsViewController(
            embeddedInNavigationStack: embeddedInNavigationStack,
            dependencies: DeliveryDependencies(pickupPointsManager: pickupPointsManager)
        )
    }

    func makePaymentViewController(with eventHandler: @escaping (PaymentEvent) -> Void) -> UIViewController {
        PaymentFeature.paymentViewController(with: eventHandler)
    }

    // MARK: - Private members

    private lazy var pickupPointsManager: PickupPointsManaging = DeliveryFeature.pickupPointsManager()
    private lazy var deliveryToCartSelectedPickupPointProvider: CartSelectedPickupPointProviding =
        DeliveryToCartSelectedPickupPointProviderAdapter(pickupPointsManager: pickupPointsManager)
}
