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

    deinit {
        print("[HomeCoordinator] deinit called")
    }

    override func start(_ context: CoordinatorStartContext) {
        print("[HomeCoordinator] start called")
        let item = composer.makeItem(for: .home(eventHandler: { [weak self] event in
              print("[HomeCoordinator] home event received: \(event)")
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

    private func requestPickupPoints() {
        print("[HomeCoordinator] requestPickupPoints called")
        let context = RouterNavigationStackContext(router: router)
        onEvent(.pickupPointsRequested(context: context, onClose: { [weak self] in
            print("[HomeCoordinator] pickupPoints onClose callback called")
            self?.router.pop(animated: true, completion: nil)
        }))
    }
}
