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
}

struct HomeComposer: HomeComposing {
    func makeHomeViewController(with eventHandler: @escaping HomeEventHandler) -> UIViewController {
        let service = HomeService()
        let interactor = HomeInteractor(service: service)
        let homePresenter = HomePresenter(interactor: interactor, onEvent: eventHandler)
        let homeViewController = HomeViewController()
        homePresenter.view = homeViewController
        homeViewController.viewOutput = homePresenter
        return homeViewController
    }
}
