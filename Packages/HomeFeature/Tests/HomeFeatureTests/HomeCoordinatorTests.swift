import UIKit
import Testing
@testable import Core
@testable import HomeFeature

@MainActor
struct HomeCoordinatorTests {
    @Test
    func start_pushesHomeRootWithoutAnimation() {
        let sut = makeSUT()

        sut.coordinator.start(with: sut.router)

        #expect(sut.router.pushCalls.count == 1)
        #expect(sut.router.pushCalls[0].item.viewController === sut.composer.homeViewController)
        #expect(sut.router.pushCalls[0].animated == false)
    }

    @Test
    func placeOrderTap_forwardsPlaceOrderEventToModuleOutput() {
        var receivedOrderID: Int?
        let sut = makeSUT(onEvent: { event in
            if case let .placeOrder(orderID) = event {
                receivedOrderID = orderID
            }
        })
        sut.coordinator.start(with: sut.router)

        sut.composer.homeEventHandler?(.onPlaceOrderTap(99))

        #expect(receivedOrderID == 99)
    }

    @Test
    func pickupPointTap_forwardsPickupPointsRequestToModuleOutput() {
        var didReceivePickupPointsRequest = false
        let sut = makeSUT(onEvent: { event in
            if case .pickupPointsRequested = event {
                didReceivePickupPointsRequest = true
            }
        })
        sut.coordinator.start(with: sut.router)

        sut.composer.homeEventHandler?(.onPickupPointTap)

        #expect(didReceivePickupPointsRequest == true)
    }

    @Test
    func pickupPointsOnCloseCallback_popsCurrentScreen() {
        var receivedOnClose: (() -> Void)?
        let sut = makeSUT(onEvent: { event in
            if case let .pickupPointsRequested(_, onClose) = event {
                receivedOnClose = onClose
            }
        })
        sut.coordinator.start(with: sut.router)
        sut.composer.homeEventHandler?(.onPickupPointTap)

        receivedOnClose?()

        #expect(sut.router.popCalls.last == true)
    }

    @Test
    func pickupPointTap_passesNavigationContextToModuleOutput() {
        var receivedContext: (any NavigationStackContext)?
        let sut = makeSUT(onEvent: { event in
            if case let .pickupPointsRequested(context, _) = event {
                receivedContext = context
            }
        })
        sut.coordinator.start(with: sut.router)

        sut.composer.homeEventHandler?(.onPickupPointTap)

        let externalViewController = UIViewController()
        receivedContext?.push(externalViewController, animated: true)

        #expect(sut.router.pushCalls.count == 2)
        #expect(sut.router.pushCalls.last?.item.viewController === externalViewController)
        #expect(sut.router.pushCalls.last?.animated == true)
    }
}

@MainActor
private extension HomeCoordinatorTests {
    struct SUT {
        let coordinator: HomeCoordinatingLogic<MockStackRouter>
        let composer: MockHomeComposer
        let router: MockStackRouter
    }

    func makeSUT(onEvent: @escaping (HomeNavigationOutputEvent) -> Void = { _ in }) -> SUT {
        let composer = MockHomeComposer()
        let router = MockStackRouter()
        let coordinator = HomeCoordinatingLogic<MockStackRouter>(composer: composer, onEvent: onEvent)
        return SUT(coordinator: coordinator, composer: composer, router: router)
    }
}

@MainActor
private final class MockHomeComposer: HomeComposing {
    let homeViewController = UIViewController()

    var homeEventHandler: HomePresenterEventHandler?

    func makeViewController(for route: HomeRoute) -> UIViewController {
        switch route {
        case .home(let eventHandler):
            homeEventHandler = eventHandler
            return homeViewController
        }
    }
}

@MainActor
private final class MockStackRouter: StackRouting {
    var root: RouterRoot { RouterRoot(UIViewController()) }
    func extractRootUI() -> UIViewController { return UIViewController() }

    struct PushCall {
        let item: RouterItem
        let animated: Bool
    }

    var items: [RouterItem] = []
    private(set) var pushCalls: [PushCall] = []
    private(set) var popCalls: [Bool] = []

    func push(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        pushCalls.append(PushCall(item: item, animated: animated))
        items.append(item)
        completion?()
    }

    func pop(animated: Bool, completion: (() -> Void)?) {
        popCalls.append(animated)
        if items.isEmpty == false {
            _ = items.removeLast()
        }
        completion?()
    }

    func popToRoot(animated: Bool, completion: (() -> Void)?) {
        completion?()
    }

    func popTo(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        completion?()
    }

    func setStack(_ items: [RouterItem], animated: Bool) {
        self.items = items
    }
    
    func present(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {}
    func dismiss(animated: Bool, completion: (() -> Void)?) {}
}
