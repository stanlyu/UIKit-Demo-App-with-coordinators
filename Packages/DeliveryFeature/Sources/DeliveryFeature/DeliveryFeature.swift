//
//  DeliveryFeature.swift
//  DeliveryFeature
//
//  Created by Любченко Станислав Валерьевич on 22.12.2025.
//

import UIKit

@MainActor
public func pickupPointsViewController(embeddedInNavigationStack: Bool = false) -> UIViewController {
    let coordinator = DeliveryCoordinator(composer: DeliveryComposer())
    if embeddedInNavigationStack {
        return coordinator
    } else {
        let navigationController = UINavigationController(rootViewController: coordinator)
        navigationController.navigationBar.prefersLargeTitles = true
        return navigationController
    }
}
