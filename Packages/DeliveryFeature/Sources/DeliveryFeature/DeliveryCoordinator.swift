//
//  DeliveryCoordinator.swift
//  DeliveryFeature
//
//  Created by Любченко Станислав Валерьевич on 22.12.2025.
//

import UIKit
import Core

final class DeliveryCoordinator: ProxyViewController {

    init(composer: DeliveryComposing) {
        self.composer = composer
        super.init(nibName: nil, bundle: nil)
        let pickupPointsVC = composer.makePickupPointsViewController { [unowned self] event in
            handle(event: event)
        }
        setContent(pickupPointsVC)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private members

    private let composer: DeliveryComposing

    private func handle(event: PickupPointsPresenter.Event) {
        switch event {
        case .onAddPickupPoint:
            let addPickupPointViewController = composer.makeAddPickupPointViewController { [unowned self] event in
                switch event {
                case .onBackTap:
                    navigationController?.popViewController(animated: true)
                }
            }
            navigationController?.pushViewController(addPickupPointViewController, animated: true)
        }
    }
}
