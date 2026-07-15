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
            let homeViewController = HomeModule.create(
                dependencies: HomeBusinessDependencies(externalScreensProvider: HomeExternalScreensProviderProxy(composer: self)),
                onEvent: onEvent
            )
            homeViewController.tabBarItem = UITabBarItem(title: "Главная", image: nil, selectedImage: nil)
            return homeViewController
            
        case let .cart(onCreated, onEvent):
            let dependencies = CartBusinessDependencies(
                selectedPickupPointProvider: deliveryToCartSelectedPickupPointProvider,
                externalScreensProvider: CartExternalScreensProviderProxy(composer: self)
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

    func makeHomePickupPointsViewController(onClose: @escaping () -> Void) -> UIViewController {
        makeViewController(for: .pickupPoints(embeddedInNavigationStack: true, onEvent: { event in
            switch event {
            case .didClose:
                onClose()
            }
        }))
    }

    func makeCartPickupPointsViewController(onClose: @escaping () -> Void) -> UIViewController {
        makeViewController(for: .pickupPoints(embeddedInNavigationStack: false, onEvent: { event in
            switch event {
            case .didClose:
                onClose()
            }
        }))
    }

    func makePaymentViewController(onComplete: @escaping (CartPaymentResult?) -> Void) -> UIViewController {
        makeViewController(for: .payment(onComplete: onComplete))
    }
    
    private lazy var pickupPointsManager: PickupPointsManaging = PickupPointModule.makePickupPointsManager()
    private lazy var deliveryToCartSelectedPickupPointProvider: CartSelectedPickupPointProviding =
        DeliveryToCartSelectedPickupPointProviderAdapter(pickupPointsManager: pickupPointsManager)
}

@MainActor
private final class CartExternalScreensProviderProxy: CartExternalScreensProvider {
    private weak var composer: MainTabsComposer?
    init(composer: MainTabsComposer) {
        self.composer = composer
    }
    func makePickupPointsViewController(onClose: @escaping () -> Void) -> UIViewController {
        composer?.makeCartPickupPointsViewController(onClose: onClose) ?? UIViewController()
    }
    func makePaymentViewController(onComplete: @escaping (CartPaymentResult?) -> Void) -> UIViewController {
        composer?.makePaymentViewController(onComplete: onComplete) ?? UIViewController()
    }
}

@MainActor
private final class HomeExternalScreensProviderProxy: HomeExternalScreensProvider {
    private weak var composer: MainTabsComposer?
    init(composer: MainTabsComposer) {
        self.composer = composer
    }
    func makePickupPointsViewController(onClose: @escaping () -> Void) -> UIViewController {
        composer?.makeHomePickupPointsViewController(onClose: onClose) ?? UIViewController()
    }
}
