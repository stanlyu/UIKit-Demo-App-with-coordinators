import UIKit
import Core

typealias HomeCoordinator = HomeCoordinatingLogic

final class HomeCoordinatingLogic: BaseCoordinator<any StackNavigation, HomeRoute> {
    init<C: HomeComposing>(
        router: any StackNavigation,
        composer: C,
        onEvent: @escaping (HomeNavigationOutputEvent) -> Void
    ) {
        self.onEvent = onEvent
        super.init(router: router, composer: composer)
    }

    override func start(_ context: CoordinatorStartContext) {
        let item = composer.makeItem(for: .home(eventHandler: { [weak self] event in
              switch event {
              case .onPlaceOrderTap(let orderID):
                  self?.onEvent(.placeOrder(orderID: orderID))
              case .onPickupPointTap:
                  self?.requestPickupPoints()
              }
          }))
        router.push(item, animated: false, completion: nil)
    }

    private let onEvent: (HomeNavigationOutputEvent) -> Void

    private func requestPickupPoints() {
        let context = RouterNavigationStackContext(router: router)
        onEvent(.pickupPointsRequested(context: context, onClose: { [weak self] in
            self?.router.pop(animated: true, completion: nil)
        }))
    }
}
