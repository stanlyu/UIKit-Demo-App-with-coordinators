//
//  MainTabsComposer+HomeExternalModulesFactory.swift
//  Demo App With Coordinators
//
//  Created by Любченко Станислав Валерьевич on 27.02.2026.
//

import UIKit
import HomeFeature
import DeliveryFeature

@MainActor
extension MainTabsComposer: HomeExternalModulesFactory {
    func makePickupPointsViewController(onClose: @escaping () -> Void) -> UIViewController {
        makePickupPointsViewController(
            embeddedInNavigationStack: true,
            eventHandler: { event in
                switch event {
                case .closed:
                    onClose()
                }
            }
        )
    }
}
