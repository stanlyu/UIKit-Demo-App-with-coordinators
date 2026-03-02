import UIKit
import HomeFeature
import CartFeature
import DeliveryFeature
import Core

enum MainTabsRoute {
    case home(eventHandler: (HomeEvent) -> Void)
    case cart(onCreated: (CartInput) -> Void)
}

@MainActor
protocol MainTabsComposing: Composing where Route == MainTabsRoute {}

final class MainTabsComposer: MainTabsComposing {
    func makeViewController(for route: MainTabsRoute) -> UIViewController {
        switch route {
        case .home(let eventHandler):
            let dependencies = HomeDependencies(externalModulesFactory: self)
            let homeViewController = homeViewController(
                with: eventHandler,
                dependencies: dependencies
            )
            homeViewController.tabBarItem = UITabBarItem(title: "Главная", image: nil, selectedImage: nil)
            return homeViewController
            
        case .cart(let onCreated):
            let dependencies = CartDependencies(
                selectedPickupPointProvider: deliveryToCartSelectedPickupPointProvider,
                externalModulesFactory: self
            )
            let cartModule = cartModule(dependencies: dependencies)
            cartModule.viewController.tabBarItem = UITabBarItem(title: "Корзина", image: nil, selectedImage: nil)
            onCreated(cartModule.coordinator)
            return cartModule.viewController
        }
    }
    
    func makePickupPointsViewController(
        embeddedInNavigationStack: Bool,
        eventHandler: ((DeliveryFlowEvent) -> Void)?
    ) -> UIViewController {
        DeliveryFeature.pickupPointsViewController(
            embeddedInNavigationStack: embeddedInNavigationStack,
            dependencies: DeliveryDependencies(pickupPointsManager: pickupPointsManager),
            eventHandler: eventHandler
        )
    }
    
    private lazy var pickupPointsManager: PickupPointsManaging = DeliveryFeature.pickupPointsManager()
    private lazy var deliveryToCartSelectedPickupPointProvider: CartSelectedPickupPointProviding =
    DeliveryToCartSelectedPickupPointProviderAdapter(pickupPointsManager: pickupPointsManager)
}
