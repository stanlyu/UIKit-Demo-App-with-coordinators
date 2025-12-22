//
//  HomeComposer.swift
//  HomeFeature
//
//  Created by Любченко Станислав Валерьевич on 19.12.2025.
//

import UIKit

@MainActor
protocol HomeComposing {
    func makeHomeNavigationController(
        with eventHandler: @escaping (HomeScreenEvent) -> Void
    ) -> UINavigationController
}

struct HomeComposer: HomeComposing {
    func makeHomeNavigationController(
        with eventHandler: @escaping (HomeScreenEvent) -> Void
    ) -> UINavigationController {
        let service = HomeService()
        let interactor = HomeInteractor(service: service)
        let homePresenter = HomePresenter(interactor: interactor, onEvent: eventHandler)
        let homeViewController = HomeViewController()
        homePresenter.view = homeViewController
        homeViewController.viewOutput = homePresenter
        homeViewController.title = "Главная"

        let action = UIAction { _ in
            eventHandler(.selectPickupPoint)
        }

        homeViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "ПВЗ", primaryAction: action)
        let navigationController = UINavigationController(rootViewController: homeViewController)
        navigationController.navigationBar.prefersLargeTitles = true
        return navigationController
    }
}
