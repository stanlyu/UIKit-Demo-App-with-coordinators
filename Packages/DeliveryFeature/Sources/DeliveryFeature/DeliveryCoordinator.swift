import UIKit
import Core

typealias DeliveryStackCoordinator = DeliveryCoordinatingLogic<StackRouter>
typealias DeliveryInlineCoordinator = DeliveryCoordinatingLogic<InlineRouter>

final class DeliveryCoordinatingLogic<Router: StackRouting>: Coordinator<Router, DeliveryRoute> {
    
    init<C: DeliveryComposing>(
        composer: C,
        flowEventHandler: ((DeliveryFlowEvent) -> Void)? = nil
    ) {
        self.flowEventHandler = flowEventHandler
        super.init(composer: composer)
    }
    
    override func start(_ capability: StartCapability) {
        let item = composer.makeItem(for: .pickupPoints(eventHandler: { [weak self] event in
            self?.handle(event: event)
        }))
        router?.push(item, animated: false, completion: nil)
    }
    
    private let flowEventHandler: ((DeliveryFlowEvent) -> Void)?
    
    private func handle(event: PickupPointsPresenter.Event) {
        switch event {
        case .onAddPickupPoint:
            let item = composer.makeItem(for: .addPickupPoint(eventHandler: { [weak self] event in
                switch event {
                case .onBackTap:
                    self?.router?.pop(animated: true, completion: nil)
                }
            }))
            router?.push(item, animated: true, completion: nil)
            
        case let .onFavoriteDeleteRequested(pickupPoint, input):
            let item = composer.makeItem(for: .deleteConfirmation(pickupPoint: pickupPoint, onConfirm: {
                input.confirmDeleteFavoritePickupPoint(pickupPoint)
            }))
            router?.present(item, animated: true, completion: nil)
            
        case .onCloseRequested:
            flowEventHandler?(.closed)
        }
    }
}
