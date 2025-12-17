//
//  RootComposer.swift
//  Demo App With Coordinators
//
//  Created by Любченко Станислав Валерьевич on 17.12.2025.
//

import UIKit

protocol RootComposing {
    func makeLaunchViewController(with eventHandler: @escaping (LaunchScreenEvent) -> Void) -> UIViewController
    func makeMainTabsViewController() -> UIViewController
}

struct RootComposer: RootComposing {
    func makeLaunchViewController(with eventHandler: @escaping (LaunchScreenEvent) -> Void) -> UIViewController {
        let viewController = LaunchViewController()
        let presenter = LaunchPresenter(
            interactor: LaunchInteractor(),
            onEvent: eventHandler
        )
        viewController.output = presenter
        presenter.view = viewController
        return viewController
    }

    func makeMainTabsViewController() -> UIViewController {
        let tabBarController = UITabBarController()
        
        // Создаем первую вкладку "Главная"
        let homeViewController = UIViewController()
        homeViewController.title = "Главная"
        homeViewController.tabBarItem = UITabBarItem(
            title: "Главная",
            image: nil, // Можно добавить иконку позже
            selectedImage: nil
        )
        
        // Создаем вторую вкладку "Корзина"
        let cartViewController = UIViewController()
        cartViewController.title = "Корзина"
        cartViewController.tabBarItem = UITabBarItem(
            title: "Корзина",
            image: nil, // Можно добавить иконку позже
            selectedImage: nil
        )
        
        // Настраиваем цвет вкладок
        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            tabBarController.tabBar.standardAppearance = appearance
            tabBarController.tabBar.scrollEdgeAppearance = appearance
        }
        
        // Добавляем вкладки в контроллер
        tabBarController.viewControllers = [homeViewController, cartViewController]
        
        return tabBarController
    }
}
