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
        var receivedEvents: [HomeEvent] = []
        let sut = makeSUT(eventHandler: { receivedEvents.append($0) })
        sut.coordinator.start(with: sut.router)

        sut.composer.homeEventHandler?(.onPlaceOrderTap(99))

        guard let event = receivedEvents.last else {
            Issue.record("Не получено событие .placeOrder")
            return
        }
        guard case let .placeOrder(orderID) = event else {
            Issue.record("Ожидалось событие .placeOrder")
            return
        }
        #expect(orderID == 99)
    }

    @Test
    func pickupPointTap_requestsExternalPickupPointsViewController() {
        let sut = makeSUT()
        sut.coordinator.start(with: sut.router)

        sut.composer.homeEventHandler?(.onPickupPointTap)

        #expect(sut.composer.makePickupPointsViewControllerCallsCount == 1)
    }

    @Test
    func pickupPointTap_pushesPickupPointsViewControllerAnimated() {
        let sut = makeSUT()
        sut.coordinator.start(with: sut.router)

        sut.composer.homeEventHandler?(.onPickupPointTap)

        #expect(sut.router.pushCalls.count == 2)
        #expect(sut.router.pushCalls[1].item.viewController === sut.composer.pickupPointsViewController)
        #expect(sut.router.pushCalls[1].animated == true)
    }

    @Test
    func pickupPointsOnCloseCallback_popsCurrentScreen() {
        let sut = makeSUT()
        sut.coordinator.start(with: sut.router)
        sut.composer.homeEventHandler?(.onPickupPointTap)

        sut.composer.pickupPointsOnClose?()

        #expect(sut.router.popCalls.last == true)
    }

    @Test
    func pickupPointTap_pushesPickupPointsScreen() {
        let sut = makeSUT()
        sut.coordinator.start(with: sut.router)

        sut.composer.homeEventHandler?(.onPickupPointTap)

        #expect(sut.router.pushCalls.count == 2)
    }
}

@MainActor
private extension HomeCoordinatorTests {
    struct SUT {
        let coordinator: HomeCoordinatingLogic<MockStackRouter>
        let composer: MockHomeComposer
        let router: MockStackRouter
    }

    func makeSUT(eventHandler: @escaping (HomeEvent) -> Void = { _ in }) -> SUT {
        let composer = MockHomeComposer()
        let router = MockStackRouter()
        let coordinator = HomeCoordinatingLogic<MockStackRouter>(composer: composer, eventHandler: eventHandler)
        return SUT(coordinator: coordinator, composer: composer, router: router)
    }
}

@MainActor
private final class MockHomeComposer: HomeComposing {
    let homeViewController = UIViewController()
    let pickupPointsViewController = UIViewController()

    private(set) var makePickupPointsViewControllerCallsCount = 0

    var homeEventHandler: HomeEventHandler?
    var pickupPointsOnClose: (() -> Void)?

    func makeViewController(for route: HomeRoute) -> UIViewController {
        switch route {
        case .home(let eventHandler):
            homeEventHandler = eventHandler
            return homeViewController
        case .pickupPoints(let onClose):
            makePickupPointsViewControllerCallsCount += 1
            pickupPointsOnClose = onClose
            return pickupPointsViewController
        }
    }
}

@MainActor
private final class MockStackRouter: StackRouting {
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
