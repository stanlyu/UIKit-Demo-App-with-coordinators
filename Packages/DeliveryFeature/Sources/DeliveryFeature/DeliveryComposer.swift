//
//  DeliveryComposer.swift
//  DeliveryFeature
//
//  Created by Любченко Станислав Валерьевич on 22.12.2025.
//

import UIKit

protocol DeliveryComposing {
    func makePickupPointsViewController() -> UINavigationController
}

struct DeliveryComposer: DeliveryComposing {
    func makePickupPointsViewController() -> UINavigationController {
        #warning("TODO: Implement makePickupPointsViewController in DeliveryComposer")
        return UINavigationController(rootViewController: UIViewController())
    }
}
