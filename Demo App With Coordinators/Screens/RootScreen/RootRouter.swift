//
//  RootRouter.swift
//  Demo App With Coordinators
//
//  Created by Любченко Станислав Валерьевич on 17.12.2025.
//

import UIKit

protocol RootRouting: AnyObject {
    func routeToViewController(_ viewController: UIViewController)
}

final class RootRouter: UIViewController, RootRouting {
    private var contentViewController: UIViewController?
    private let contentProvider: RootContentProviding

    init(contentProvider: RootContentProviding) {
        self.contentProvider = contentProvider
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addChildViewControllerInternal(contentProvider.content)
    }
    
    func routeToViewController(_ viewController: UIViewController) {
        guard let oldViewController = contentViewController else {
            addChildViewControllerInternal(viewController)
            return
        }

        addChild(viewController)
        setupChildView(viewController.view)

        viewController.view.alpha = 0
        view.layoutIfNeeded()
        oldViewController.willMove(toParent: nil)

        UIView.animate(withDuration: 0.3) {
            viewController.view.alpha = 1
        } completion: { finished in
            oldViewController.view.removeFromSuperview()
            oldViewController.removeFromParent()
            viewController.didMove(toParent: self)
            self.contentViewController = viewController
        }
    }
    
    private func addChildViewControllerInternal(_ viewController: UIViewController) {
        addChild(viewController)
        setupChildView(viewController.view)
        viewController.didMove(toParent: self)
        contentViewController = viewController
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
}
