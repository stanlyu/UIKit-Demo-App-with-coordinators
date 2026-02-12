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
    func makeHomeViewController(with eventHandler: @escaping (HomeEvent) -> Void) -> UIViewController & HomeInput
    func makeCartViewController(with eventHandler: @escaping (CartEvent) -> Void) -> UIViewController & CartInput
}

struct MainTabsComposer: MainTabsComposing {
    func makeHomeViewController(with eventHandler: @escaping (HomeEvent) -> Void) -> UIViewController & HomeInput {
        let homeViewController = homeViewController(with: eventHandler)
        homeViewController.title = "Главная"
        homeViewController.tabBarItem = UITabBarItem(
            title: "Главная",
            image: nil,
            selectedImage: nil
        )
        return homeViewController
    }

    func makeCartViewController(with eventHandler: @escaping (CartEvent) -> Void) -> UIViewController & CartInput {
        let cartViewController = cartViewController(with: eventHandler)
        cartViewController.tabBarItem = UITabBarItem(
            title: "Корзина",
            image: nil,
            selectedImage: nil
        )
        return cartViewController
    }
}
