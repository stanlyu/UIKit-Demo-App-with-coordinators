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

@MainActor
protocol MainTabsComposing {
    func makeHomeViewController(with eventHandler: @escaping (HomeEvent) -> Void) -> UIViewController
    func makeCartViewController() -> CartModule
}

final class MainTabsComposer: MainTabsComposing {
    func makeHomeViewController(with eventHandler: @escaping (HomeEvent) -> Void) -> UIViewController {
        let dependencies = HomeDependencies(externalModulesFactory: self)

        let homeViewController = homeViewController(
            with: eventHandler,
            dependencies: dependencies
        )
        homeViewController.tabBarItem = UITabBarItem(
            title: "Главная",
            image: nil,
            selectedImage: nil
        )
        return homeViewController
    }

    func makeCartViewController() -> CartModule {
        let dependencies = CartDependencies(
            selectedPickupPointProvider: deliveryToCartSelectedPickupPointProvider,
            externalModulesFactory: self
        )
        let cartModule = cartModule(dependencies: dependencies)
        cartModule.viewController.tabBarItem = UITabBarItem(
            title: "Корзина",
            image: nil,
            selectedImage: nil
        )
        return cartModule
    }

    // Используется bridge-слоем для сборки внешних экранов.
    func makePickupPointsViewController(
        embeddedInNavigationStack: Bool,
        eventHandler: ((DeliveryFlowEvent) -> Void)?
    ) -> UIViewController {
        DeliveryFeature.pickupPointsViewController(
            embeddedInNavigationStack: embeddedInNavigationStack,
            dependencies: DeliveryDependencies(pickupPointsManager: pickupPointsManager),
            eventHandler: eventHandler
        )
    }

    // MARK: - Private members

    private lazy var pickupPointsManager: PickupPointsManaging = DeliveryFeature.pickupPointsManager()
    private lazy var deliveryToCartSelectedPickupPointProvider: CartSelectedPickupPointProviding =
        DeliveryToCartSelectedPickupPointProviderAdapter(pickupPointsManager: pickupPointsManager)
}
