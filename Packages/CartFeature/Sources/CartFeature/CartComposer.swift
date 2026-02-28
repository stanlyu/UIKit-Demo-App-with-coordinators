import UIKit
import Core

typealias CartEventHandler = (CartPresenter.Event) -> Void
typealias PlaceOrderEventHandler = (PlaceOrderPresenter.Event) -> Void
typealias OrderConfirmationEventHandler = (OrderConfirmationPresenter.Event) -> Void

enum CartRoute {
    case cart(eventHandler: CartEventHandler)
    case placeOrder(orderID: Int, eventHandler: PlaceOrderEventHandler)
    case orderConfirmation(paymentResult: CartPaymentResult, eventHandler: OrderConfirmationEventHandler)
    case pickupPoints
    case payment(onComplete: (CartPaymentResult?) -> Void)
}

@MainActor
protocol CartComposing: Composing where Route == CartRoute {}

struct CartComposer: CartComposing {
    init(dependencies: CartDependencies) {
        self.dependencies = dependencies
    }

    func makeViewController(for route: CartRoute, capability: ComposeCapability) -> UIViewController {
        switch route {
        case .cart(let eventHandler):
            let service = CartService()
            let interactor = CartInteractor(service: service)
            let presenter = CartPresenter(interactor: interactor, onEvent: eventHandler)
            let cartViewController = CartViewController()
            presenter.view = cartViewController
            cartViewController.viewOutput = presenter
            return cartViewController

        case let .placeOrder(orderID, eventHandler):
            let service = PlaceOrderService()
            let interactor = PlaceOrderInteractor(
                orderID: orderID,
                service: service,
                selectedPickupPointProvider: dependencies.selectedPickupPointProvider
            )
            let presenter = PlaceOrderPresenter(interactor: interactor, onEvent: eventHandler)
            let viewController = PlaceOrderViewController()
            presenter.view = viewController
            viewController.viewOutput = presenter
            //            viewController.hidesBottomBarWhenPushed = true
            return viewController

        case let .orderConfirmation(paymentResult, eventHandler):
            let presenter = OrderConfirmationPresenter(paymentResult: paymentResult, onEvent: eventHandler)
            let viewController = OrderConfirmationViewController()
            presenter.view = viewController
            viewController.viewOutput = presenter
            return viewController

        case .pickupPoints:
            guard let externalModulesFactory = dependencies.externalModulesFactory else {
                assertionFailure("External modules factory is missing")
                return UIViewController()
            }
            return externalModulesFactory.makePickupPointsViewController()

        case .payment(let onComplete):
            guard let externalModulesFactory = dependencies.externalModulesFactory else {
                assertionFailure("External modules factory is missing")
                return UIViewController()
            }
            return externalModulesFactory.makePaymentViewController(onComplete: onComplete)
        }
    }

    private let dependencies: CartDependencies
}
