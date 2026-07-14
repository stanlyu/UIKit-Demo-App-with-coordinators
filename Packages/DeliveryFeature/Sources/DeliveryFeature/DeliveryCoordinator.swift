import UIKit
import Core

typealias DeliveryCoordinator = DeliveryCoordinatingLogic

final class DeliveryCoordinatingLogic: BaseCoordinator<any StackNavigation, DeliveryRoute> {
    
    init<C: DeliveryComposing>(
        router: any StackNavigation,
        composer: C,
        onEvent: ((PickupPointNavigationOutputEvent) -> Void)? = nil
    ) {
        self.onEvent = onEvent
        super.init(router: router, composer: composer)
    }
    
    override func start(_ context: CoordinatorStartContext) {
        let item = composer.makeItem(for: .pickupPoints(eventHandler: { [weak self] event in
            self?.handle(event: event)
        }))
        router.push(item, animated: false, completion: nil)
    }
    
    private let onEvent: ((PickupPointNavigationOutputEvent) -> Void)?
    
    private func handle(event: PickupPointsPresenter.Event) {
        switch event {
        case .onAddPickupPoint:
            let item = composer.makeItem(for: .addPickupPoint(eventHandler: { [weak self] event in
                switch event {
                case .onBackTap:
                    self?.router.pop(animated: true, completion: nil)
                }
            }))
            router.push(item, animated: true, completion: nil)
            
        case let .onFavoriteDeleteRequested(pickupPoint, input):
            let item = composer.makeItem(for: .deleteConfirmation(pickupPoint: pickupPoint, onConfirm: {
                input.confirmDeleteFavoritePickupPoint(pickupPoint)
            }))
            router.present(item, animated: true, completion: nil)
            
        case .onCloseRequested:
            onEvent?(.didClose)
        }
    }
}
