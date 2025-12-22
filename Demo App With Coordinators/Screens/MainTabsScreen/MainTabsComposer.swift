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
    func makeTabBarController(with viewControllers: [UIViewController]) -> UITabBarController
    func makeHomeViewController(with eventHandler: @escaping (HomeEvent) -> Void) -> UIViewController
    func makeCartViewController(with inputProvider: (CartInput) -> Void) -> UIViewController
}

struct MainTabsComposer: MainTabsComposing {
    func makeTabBarController(with viewControllers: [UIViewController]) -> UITabBarController {
        let tabBarController = UITabBarController()

        // Настраиваем цвет вкладок
        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            tabBarController.tabBar.standardAppearance = appearance
            tabBarController.tabBar.scrollEdgeAppearance = appearance
        }

        tabBarController.viewControllers = viewControllers
        return tabBarController
    }

    func makeHomeViewController(with eventHandler: @escaping (HomeEvent) -> Void) -> UIViewController {
        let homeViewController = homeViewController(with: eventHandler)
        homeViewController.title = "Главная"
        homeViewController.tabBarItem = UITabBarItem(
            title: "Главная",
            image: nil,
            selectedImage: nil
        )
        return homeViewController
    }

    func makeCartViewController(with inputProvider: (CartInput) -> Void) -> UIViewController {
        let cartViewController = cartViewController(with: inputProvider)
        cartViewController.title = "Корзина"
        cartViewController.tabBarItem = UITabBarItem(
            title: "Корзина",
            image: nil,
            selectedImage: nil
        )
        #warning("TODO: Implement makeCartViewController in MainTabsComposer")
        return cartViewController
    }
}
