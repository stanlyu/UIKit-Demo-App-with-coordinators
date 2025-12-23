//
//  ApplicationCoordinator.swift
//  Demo App With Coordinators
//
//  Created by Любченко Станислав Валерьевич on 17.12.2025.
//

import UIKit
import Core

final class ApplicationCoordinator: UIViewController {

    init(composer: ApplicationComposing = ApplicationComposer()) {
        self.composer = composer
        super.init(nibName: nil, bundle: nil)
        contentViewController = composer.makeLaunchViewController { [unowned self] event in
            self.handleLaunchEvent(event)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupChildViewController(contentViewController)
    }

    // MARK: - Private members

    private let composer: ApplicationComposing
    private var contentViewController: UIViewController!

    private func routeToViewController(_ viewController: UIViewController) {
        addChild(viewController)
        setupChildView(viewController.view)

        viewController.view.alpha = 0
        view.layoutIfNeeded()
        contentViewController.willMove(toParent: nil)

        UIView.animate(withDuration: 0.3) {
            viewController.view.alpha = 1
        } completion: { finished in
            self.contentViewController.view.removeFromSuperview()
            self.contentViewController.removeFromParent()
            viewController.didMove(toParent: self)
            self.contentViewController = viewController
        }
    }

    private func setupChildView(_ childView: UIView) {
        view.addSubview(childView)

        childView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            childView.topAnchor.constraint(equalTo: view.topAnchor),
            childView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            childView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            childView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func handleLaunchEvent(_ event: LaunchScreenEvent) {
        switch event {
        case .mainFlowStarted:
            routeToViewController(composer.makeMainTabsViewController())
        }
    }
}

protocol RootContentProviding: AnyObject {
    var content: UIViewController { get }
}

extension ApplicationCoordinator: RootContentProviding {
    var content: UIViewController {
        composer.makeLaunchViewController(with: handleLaunchEvent)
    }
}
