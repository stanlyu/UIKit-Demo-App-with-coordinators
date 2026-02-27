//
//  DeliveryCoordinator.swift
//  DeliveryFeature
//
//  Created by Любченко Станислав Валерьевич on 22.12.2025.
//

import UIKit
import Core

typealias DeliveryStackCoordinator = DeliveryCoordinatingLogic<StackRouter>
typealias DeliveryInlineCoordinator = DeliveryCoordinatingLogic<InlineRouter>

final class DeliveryCoordinatingLogic<Router: StackRouting>: Coordinator<Router> {

    init(
        composer: DeliveryComposing,
        flowEventHandler: ((DeliveryFlowEvent) -> Void)? = nil
    ) {
        self.composer = composer
        self.flowEventHandler = flowEventHandler
        super.init()

    }

    override func start(_ capability: StartCapability) {
        let pickupPointsVC = composer.makePickupPointsViewController { [unowned self] event in
            handle(event: event)
        }
        router?.push(pickupPointsVC, animated: false, completion: nil)
    }

    // MARK: - Private members

    private let composer: DeliveryComposing
    private let flowEventHandler: ((DeliveryFlowEvent) -> Void)?

    private func handle(event: PickupPointsPresenter.Event) {
        switch event {
        case .onAddPickupPoint:
            let addPickupPointViewController = composer.makeAddPickupPointViewController { [unowned self] event in
                switch event {
                case .onBackTap:
                    router?.pop(animated: true, completion: nil)
                }
            }
            router?.push(addPickupPointViewController, animated: true, completion: nil)

        case let .onFavoriteDeleteRequested(pickupPoint, input):
            let deleteConfirmationViewController = composer.makeFavoritePickupPointDeleteConfirmationViewController(
                pickupPoint: pickupPoint
            ) {
                input.confirmDeleteFavoritePickupPoint(pickupPoint)
            }
            router?.present(deleteConfirmationViewController, animated: true, completion: nil)

        case .onCloseRequested:
            flowEventHandler?(.closed)
        }
    }
}
