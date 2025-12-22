//
//  UIViewController.swift
//  Core
//
//  Created by Любченко Станислав Валерьевич on 22.12.2025.
//

import UIKit

public extension UIViewController {
    func setupChildViewController(_ viewController: UIViewController) {
        addChild(viewController)
        view.addSubview(viewController.view)

        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            viewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            viewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            viewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            viewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        viewController.didMove(toParent: self)
    }

    func activateNavigationRightBarButton() {
        if #available(iOS 16.0, *) {
            navigationItem.rightBarButtonItem?.isHidden = false
        } else {
            navigationItem.rightBarButtonItem?.isEnabled = true
        }
    }

    func deactivateNavigationRightBarButton() {
        if #available(iOS 16.0, *) {
            navigationItem.rightBarButtonItem?.isHidden = true
        } else {
            navigationItem.rightBarButtonItem?.isEnabled = false
        }
    }
}
