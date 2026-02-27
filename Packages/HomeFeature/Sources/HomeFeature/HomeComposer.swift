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
    func makeHomeViewController(with eventHandler: @escaping HomeEventHandler) -> UIViewController
    func makePickupPointsViewController(onClose: @escaping () -> Void) -> UIViewController
}

struct HomeComposer: HomeComposing {
    init(dependencies: HomeDependencies) {
        self.dependencies = dependencies
    }

    func makeHomeViewController(with eventHandler: @escaping HomeEventHandler) -> UIViewController {
        let service = HomeService()
        let interactor = HomeInteractor(service: service)
        let homePresenter = HomePresenter(interactor: interactor, onEvent: eventHandler)
        let homeViewController = HomeViewController()
        homePresenter.view = homeViewController
        homeViewController.viewOutput = homePresenter
        return homeViewController
    }

    func makePickupPointsViewController(onClose: @escaping () -> Void) -> UIViewController {
        guard let externalModulesFactory = dependencies.externalModulesFactory else {
            assertionFailure("External modules factory is missing")
            return UIViewController()
        }
        return externalModulesFactory.makePickupPointsViewController(onClose: onClose)
    }

    // MARK: - Private members

    private let dependencies: HomeDependencies
}
