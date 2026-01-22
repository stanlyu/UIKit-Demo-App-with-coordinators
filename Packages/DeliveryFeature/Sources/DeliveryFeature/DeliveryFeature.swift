//
//  DeliveryFeature.swift
//  DeliveryFeature
//
//  Created by Любченко Станислав Валерьевич on 22.12.2025.
//

import UIKit

public func pickupPointsViewController(embeddedInNavigationStack: Bool = false) -> UIViewController {
    if embeddedInNavigationStack {
        return DeliveryCoordinator(composer: DeliveryComposer())
    } else {
        let coordinator = DeliveryNavigationCoordinator(composer: DeliveryComposer())
        coordinator.navigationBar.prefersLargeTitles = true
        return coordinator
    }
}
