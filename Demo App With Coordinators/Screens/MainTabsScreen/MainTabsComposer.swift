import UIKit
import HomeFeature
import CartFeature
import DeliveryFeature
import PaymentFeature
import Core

enum MainTabsRoute {
    case home(onEvent: (HomeNavigationOutputEvent) -> Void)
    case cart(onCreated: (any CartNavigationInput) -> Void, onEvent: (CartNavigationOutputEvent) -> Void)
    case pickupPoints(embeddedInNavigationStack: Bool, onEvent: ((PickupPointNavigationOutputEvent) -> Void)?)
    case payment(onComplete: (CartPaymentResult?) -> Void)
}

@MainActor
protocol MainTabsComposing: Composing where Route == MainTabsRoute {}

final class MainTabsComposer: MainTabsComposing {
    func makeViewController(for route: MainTabsRoute) -> UIViewController {
        switch route {
        case .home(let onEvent):
            let homeViewController = HomeModule.create(onEvent: onEvent)
            homeViewController.tabBarItem = UITabBarItem(title: "Главная", image: nil, selectedImage: nil)
            return homeViewController
            
        case let .cart(onCreated, onEvent):
            let dependencies = CartBusinessDependencies(
                selectedPickupPointProvider: deliveryToCartSelectedPickupPointProvider
            )
            let cartModule = CartModule.create(dependencies: dependencies, onEvent: onEvent)
            cartModule.viewController.tabBarItem = UITabBarItem(title: "Корзина", image: nil, selectedImage: nil)
            onCreated(cartModule.navigationInput)
            return cartModule.viewController

        case let .pickupPoints(embeddedInNavigationStack, onEvent):
            return PickupPointModule.create(
                embeddedInNavigationStack: embeddedInNavigationStack,
                dependencies: PickupPointBusinessDependencies(pickupPointsManager: pickupPointsManager),
                onEvent: onEvent
            )

        case .payment(let onComplete):
            return PaymentModule.create { [weak self] event in
                guard let self else { return }

                switch event {
                case .cancelled:
                    onComplete(nil)
                case let .completed(paymentResult):
                    onComplete(makeCartPaymentResult(from: paymentResult))
                }
            }
        }
    }
    
    private lazy var pickupPointsManager: PickupPointsManaging = PickupPointModule.makePickupPointsManager()
    private lazy var deliveryToCartSelectedPickupPointProvider: CartSelectedPickupPointProviding =
        DeliveryToCartSelectedPickupPointProviderAdapter(pickupPointsManager: pickupPointsManager)
}
