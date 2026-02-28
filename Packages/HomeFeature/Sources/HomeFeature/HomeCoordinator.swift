import UIKit
import Core

typealias HomeCoordinator = HomeCoordinatingLogic<StackRouter>

final class HomeCoordinatingLogic<Router: StackRouting>: Coordinator<Router, HomeRoute> {
    init<C: HomeComposing>(composer: C, eventHandler: @escaping (HomeEvent) -> Void) {
        self.eventHandler = eventHandler
        super.init(composer: composer)
    }

    override func start(_ capability: StartCapability) {
        let item = composer.makeItem(for: .home(eventHandler: { [weak self] event in
            switch event {
            case .onPlaceOrderTap(let orderID):
                self?.eventHandler(.placeOrder(orderID))
            case .onPickupPointTap:
                self?.showPickupPoints()
            }
        }))
        router?.push(item, animated: false, completion: nil)
    }

    private let eventHandler: (HomeEvent) -> Void

    private func showPickupPoints() {
        let item = composer.makeItem(for: .pickupPoints(onClose: { [weak self] in
            self?.router?.pop(animated: true, completion: nil)
        }))
        router?.push(item, animated: true, completion: nil)
    }
}
