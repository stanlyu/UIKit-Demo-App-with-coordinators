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
    func pickupPointTap_forwardsSelectPickupPointEventToModuleOutput() {
        var receivedEvents: [HomeEvent] = []
        let sut = makeSUT(eventHandler: { receivedEvents.append($0) })
        sut.coordinator.start(with: sut.router)

        sut.composer.homeEventHandler?(.onPickupPointTap)

        guard let event = receivedEvents.last else {
            Issue.record("Не получено событие .selectPickupPoint")
            return
        }
        guard case let .selectPickupPoint(input) = event else {
            Issue.record("Ожидалось событие .selectPickupPoint")
            return
        }
        #expect(input as AnyObject === sut.coordinator)
    }

    @Test
    func presentPickupPoints_pushesModuleAnimated() {
        let sut = makeSUT()
        let module = UIViewController()

        sut.coordinator.start(with: sut.router)
        sut.coordinator.presentPickupPoints(module: module)

        #expect(sut.router.pushCalls.count == 2)
        #expect(sut.router.pushCalls[1].viewController === module)
        #expect(sut.router.pushCalls[1].animated == true)
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
    var homeEventHandler: HomeEventHandler?

    func makeHomeViewController(with eventHandler: @escaping HomeEventHandler) -> UIViewController {
        homeEventHandler = eventHandler
        return homeViewController
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

    func push(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        pushCalls.append(PushCall(viewController: viewController, animated: animated))
        viewControllers.append(viewController)
        completion?()
    }

    func pop(animated: Bool, completion: (() -> Void)?) {
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
