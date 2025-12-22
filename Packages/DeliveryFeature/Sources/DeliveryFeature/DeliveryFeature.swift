//
//  DeliveryFeature.swift
//  DeliveryFeature
//
//  Created by Любченко Станислав Валерьевич on 22.12.2025.
//

import UIKit

public func pickupPointsViewController() -> UIViewController {
    #warning("TODO: Implement makePickupPointsViewController in DeliveryFeature")
    let viewController = UIViewController()
    viewController.title = "Выбор ПВЗ"
    let navigationController = UINavigationController(rootViewController: viewController)
    navigationController.navigationBar.prefersLargeTitles = true
    return navigationController
}
