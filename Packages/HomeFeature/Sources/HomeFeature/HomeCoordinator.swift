import UIKit
import Core

typealias HomeCoordinator = HomeCoordinatingLogic<StackRouter>

final class HomeCoordinatingLogic<Router: StackRouting>: Coordinator<Router, HomeRoute> {
    init<C: HomeComposing>(composer: C, onEvent: @escaping (HomeNavigationOutputEvent) -> Void) {
        self.onEvent = onEvent
        super.init(composer: composer)
    }

    override func start(_ capability: StartCapability) {
        let item = composer.makeItem(for: .home(eventHandler: { [weak self] event in
              switch event {
              case .onPlaceOrderTap(let orderID):
                  self?.onEvent(.placeOrder(orderID: orderID))
              case .onPickupPointTap:
                  self?.requestPickupPoints()
              }
          }))
        router?.push(item, animated: false, completion: nil)
    }

    private let onEvent: (HomeNavigationOutputEvent) -> Void

    private func requestPickupPoints() {
        guard let router else { return }
        let context = RouterNavigationStackContext(router: router)
        onEvent(.pickupPointsRequested(context: context, onClose: { [weak self] in
            self?.router?.pop(animated: true, completion: nil)
        }))
    }
}
