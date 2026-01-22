//
//  DeliveryFeature.swift
//  DeliveryFeature
//
//  Created by Любченко Станислав Валерьевич on 22.12.2025.
//

import UIKit

public func pickupPointsViewController(embeddedInNavigationStack: Bool = false) -> UIViewController {
    DeliveryCoordinator(composer: DeliveryComposer(), embeddedInNavigationStack: embeddedInNavigationStack)
}
