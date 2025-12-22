//
//  HomeComposer.swift
//  HomeFeature
//
//  Created by Любченко Станислав Валерьевич on 19.12.2025.
//

import UIKit

typealias HomeEventHandler = (HomePresenter.Event) -> Void

@MainActor
protocol HomeComposing {
    func makeHomeNavigationController(with eventHandler: @escaping HomeEventHandler) -> UINavigationController
}

struct HomeComposer: HomeComposing {
    func makeHomeNavigationController(with eventHandler: @escaping HomeEventHandler) -> UINavigationController {
        let service = HomeService()
        let interactor = HomeInteractor(service: service)
        let homePresenter = HomePresenter(interactor: interactor, onEvent: eventHandler)
        let homeViewController = HomeViewController()
        homePresenter.view = homeViewController
        homeViewController.viewOutput = homePresenter
        let navigationController = UINavigationController(rootViewController: homeViewController)
        navigationController.navigationBar.prefersLargeTitles = true
        return navigationController
    }
}
