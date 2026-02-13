//
//  MainTabsComposer.swift
//  Demo App With Coordinators
//
//  Created by Любченко Станислав Валерьевич on 18.12.2025.
//

import UIKit
import HomeFeature
import CartFeature

@MainActor
protocol MainTabsComposing {
    func makeHomeViewController(with eventHandler: @escaping (HomeEvent) -> Void) -> UIViewController
    func makeCartViewController(with eventHandler: @escaping (CartEvent) -> Void) -> CartModule
}

struct MainTabsComposer: MainTabsComposing {
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
        let cartModule = cartModule(with: eventHandler)
        cartModule.viewController.tabBarItem = UITabBarItem(
            title: "Корзина",
            image: nil,
            selectedImage: nil
        )
        return cartModule
    }
}
