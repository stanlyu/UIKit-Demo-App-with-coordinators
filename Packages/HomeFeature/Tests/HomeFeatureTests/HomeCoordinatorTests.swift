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
        #expect(sut.router.pushCalls[0].viewController === sut.composer.homeViewController)
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
        #expect(sut.router.pushCalls[1].viewController === sut.composer.pickupPointsViewController)
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

    func makeHomeViewController(with eventHandler: @escaping HomeEventHandler) -> UIViewController {
        homeEventHandler = eventHandler
        return homeViewController
    }

    func makePickupPointsViewController(onClose: @escaping () -> Void) -> UIViewController {
        makePickupPointsViewControllerCallsCount += 1
        pickupPointsOnClose = onClose
        return pickupPointsViewController
    }
}

@MainActor
private final class MockStackRouter: UIViewController, StackRouting {
    struct PushCall {
        let viewController: UIViewController
        let animated: Bool
    }

    var viewControllers: [UIViewController] = []
    private(set) var pushCalls: [PushCall] = []
    private(set) var popCalls: [Bool] = []

    func push(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        pushCalls.append(PushCall(viewController: viewController, animated: animated))
        viewControllers.append(viewController)
        completion?()
    }

    func pop(animated: Bool, completion: (() -> Void)?) {
        popCalls.append(animated)
        if viewControllers.isEmpty == false {
            _ = viewControllers.removeLast()
        }
        completion?()
    }

    func popToRoot(animated: Bool, completion: (() -> Void)?) {
        completion?()
    }

    func popTo(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        completion?()
    }

    func setStack(_ viewControllers: [UIViewController], animated: Bool) {
        self.viewControllers = viewControllers
    }
}
