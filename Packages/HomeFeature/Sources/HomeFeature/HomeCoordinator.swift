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
        router.setRoot(item, animated: false)
    }

    private let onEvent: (HomeNavigationOutputEvent) -> Void
    private var pickupPointsItem: RouterItem?

    private func requestPickupPoints() {
        let item = composer.makeItem(for: .pickupPoints(onClose: { [weak self] in
            self?.router.pop(animated: true, completion: nil)
        }))
        self.pickupPointsItem = item
        router.push(item, animated: true, completion: nil)
    }
}
