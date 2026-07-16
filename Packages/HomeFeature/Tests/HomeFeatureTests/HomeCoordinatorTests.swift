import UIKit
import Testing
@testable import Core
@testable import HomeFeature

@MainActor
struct HomeCoordinatorTests {
    @Test
    func start_setsHomeRootWithoutAnimation() {
        // arrange
        let sut = makeSUT()

        // act
        sut.coordinator.start(CoordinatorStartContext())

        // assert
        #expect(sut.router.setRootCalls.count == 1)
        #expect(sut.router.setRootCalls[0].item.isWrapping(sut.composer.homeViewController))
        #expect(sut.router.setRootCalls[0].animated == false)
    }

    @Test
    func placeOrderTap_forwardsPlaceOrderEventToModuleOutput() {
        // arrange
        var receivedOrderID: Int?
        let sut = makeSUT(onEvent: { event in
            if case let .placeOrder(orderID) = event {
                receivedOrderID = orderID
            }
        })

        // act
        sut.coordinator.start(CoordinatorStartContext())
        sut.composer.homeEventHandler?(.onPlaceOrderTap(99))

        // assert
        #expect(receivedOrderID == 99)
    }

    @Test
    func pickupPointTap_pushesPickupPointsScreen() {
        // arrange
        let sut = makeSUT()

        // act
        sut.coordinator.start(CoordinatorStartContext())
        sut.composer.homeEventHandler?(.onPickupPointTap)

        // assert
        #expect(sut.router.pushCalls.count == 1)
        #expect(sut.router.pushCalls[0].item.isWrapping(sut.composer.pickupPointsViewController))
        #expect(sut.router.pushCalls[0].animated == true)
    }

    @Test
    func pickupPointsOnCloseCallback_popsCurrentScreen() {
        // arrange
        let sut = makeSUT()
        sut.coordinator.start(CoordinatorStartContext())
        sut.composer.homeEventHandler?(.onPickupPointTap)

        // act
        sut.composer.pickupPointsOnClose?()

        // assert
        #expect(sut.router.popCalls.last == true)
    }
}

@MainActor
private extension HomeCoordinatorTests {
    struct SUT {
        let coordinator: HomeCoordinatingLogic
        let composer: MockHomeComposer
        let router: MockStackRouter
    }

    func makeSUT(onEvent: @escaping (HomeNavigationOutputEvent) -> Void = { _ in }) -> SUT {
        let composer = MockHomeComposer()
        let router = MockStackRouter()
        let coordinator = HomeCoordinatingLogic(router: router, composer: composer, onEvent: onEvent)
        return SUT(coordinator: coordinator, composer: composer, router: router)
    }
}

@MainActor
private final class MockHomeComposer: HomeComposing {
    let homeViewController = UIViewController()
    let pickupPointsViewController = UIViewController()

    var homeEventHandler: HomePresenterEventHandler?
    var pickupPointsOnClose: (() -> Void)?

    func makeViewController(for route: HomeRoute) -> UIViewController {
        switch route {
        case .home(let eventHandler):
            homeEventHandler = eventHandler
            return homeViewController
        case .pickupPoints(let onClose):
            pickupPointsOnClose = onClose
            return pickupPointsViewController
        }
    }
}

// Записывающий роутер для `StackNavigation`. Хранит только то, что проверяется
// в тестах; неиспользуемые команды стека — no-op заглушки.
@MainActor
private final class MockStackRouter: StackNavigation {
    struct PushCall {
        let item: RouterItem
        let animated: Bool
    }

    struct SetRootCall {
        let item: RouterItem
        let animated: Bool
    }

    private(set) var setRootCalls: [SetRootCall] = []
    private(set) var pushCalls: [PushCall] = []
    private(set) var popCalls: [Bool] = []

    var items: [RouterItem] = []

    func setRoot(_ item: RouterItem, animated: Bool) {
        setRootCalls.append(SetRootCall(item: item, animated: animated))
    }

    func push(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        pushCalls.append(PushCall(item: item, animated: animated))
        completion?()
    }

    func pop(animated: Bool, completion: (() -> Void)?) {
        popCalls.append(animated)
        completion?()
    }

    func popToRoot(animated: Bool, completion: (() -> Void)?) { completion?() }
    func popTo(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) { completion?() }
    func setStack(_ items: [RouterItem], animated: Bool) {}
    func present(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {}
    func dismiss(animated: Bool, completion: (() -> Void)?) {}
}
