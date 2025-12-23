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
    func makeCartViewController(
        with inputProvider: (CartInput) -> Void,
        eventHandler: @escaping (CartEvent) -> Void
    ) -> UIViewController
}

struct MainTabsComposer: MainTabsComposing {
    func makeTabBarController(with viewControllers: [UIViewController]) -> UITabBarController {
        let tabBarController = UITabBarController()

        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        let fontSize: CGFloat = 12
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize, weight: .medium),
            .foregroundColor: UIColor.secondaryLabel
        ]
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize, weight: .bold),
            .foregroundColor: UIColor.systemBlue
        ]
        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.titleTextAttributes = normalAttributes
        itemAppearance.selected.titleTextAttributes = selectedAttributes
        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance
        tabBarController.tabBar.standardAppearance = appearance
        tabBarController.tabBar.scrollEdgeAppearance = appearance
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

    func makeCartViewController(
        with inputProvider: (CartInput) -> Void,
        eventHandler: @escaping (CartEvent) -> Void
    ) -> UIViewController {
        let cartViewController = cartViewController(with: inputProvider, eventHandler: eventHandler)
        cartViewController.tabBarItem = UITabBarItem(
            title: "Корзина",
            image: nil,
            selectedImage: nil
        )
        return cartViewController
    }
}
