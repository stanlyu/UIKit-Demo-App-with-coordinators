//
//  HomeCoordinator.swift
//  HomeFeature
//
//  Created by Любченко Станислав Валерьевич on 19.12.2025.
//

import UIKit

final class HomeCoordinator: UIViewController {
    init(composer: HomeComposing, eventHandler: @escaping (HomeScreenEvent) -> Void) {
        self.composer = composer
        super.init(nibName: nil, bundle: nil)
        homeNavigationController = composer.makeHomeNavigationController(with: eventHandler)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addChild(homeNavigationController)
        view.addSubview(homeNavigationController.view)
        
        homeNavigationController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            homeNavigationController.view.topAnchor.constraint(equalTo: view.topAnchor),
            homeNavigationController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            homeNavigationController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            homeNavigationController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        homeNavigationController.didMove(toParent: self)
    }

    // MARK: - Private members

    private let composer: HomeComposing
    private var homeNavigationController: UINavigationController!
}
