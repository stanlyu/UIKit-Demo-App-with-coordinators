import UIKit
import Testing
@testable import Core
@testable import CartFeature

@MainActor
struct CartCoordinatorTests {
    @Test
    func start_pushesCartRootWithoutAnimation() {
        let sut = makeSUT()

        sut.coordinator.start(with: sut.router)

        #expect(sut.router.pushCalls.count == 1)
        #expect(sut.router.pushCalls[0].viewController === sut.composer.cartViewController)
        #expect(sut.router.pushCalls[0].animated == false)
    }

    @Test
    func placeOrder_requestsScreenForGivenOrderID() {
        let sut = makeSUT()
        sut.coordinator.start(with: sut.router)

        sut.coordinator.placeOrder(42)

        #expect(sut.composer.requestedOrderIDs == [42])
    }

    @Test
    func placeOrder_popsToRootWithoutAnimationBeforePush() {
        let sut = makeSUT()
        sut.coordinator.start(with: sut.router)

        sut.coordinator.placeOrder(42)

        #expect(sut.router.popToRootCalls == [false])
    }

    @Test
    func placeOrder_pushesPlaceOrderScreenAnimated() {
        let sut = makeSUT()
        sut.coordinator.start(with: sut.router)

        sut.coordinator.placeOrder(42)

        #expect(sut.router.pushCalls.count == 2)
        #expect(sut.router.pushCalls[1].viewController === sut.composer.placeOrderViewController)
        #expect(sut.router.pushCalls[1].animated == true)
    }

    @Test
    func placeOrderBackEvent_popsCurrentScreen() {
        let sut = makeSUT()
        sut.coordinator.start(with: sut.router)
        sut.coordinator.placeOrder(42)

        sut.composer.placeOrderEventHandler?(.onBackTap)

        #expect(sut.router.popCalls == [true])
    }

    @Test
    func placeOrderChangePickupPointEvent_forwardsEventToModuleOutput() {
        var receivedEvents: [CartEvent] = []
        let sut = makeSUT(eventHandler: { receivedEvents.append($0) })
        sut.coordinator.start(with: sut.router)
        sut.coordinator.placeOrder(42)

        sut.composer.placeOrderEventHandler?(.onChangePickupPointTap)

        guard let event = receivedEvents.last else {
            Issue.record("Не получено событие .changePickupPoint")
            return
        }
        guard case let .changePickupPoint(input) = event else {
            Issue.record("Ожидалось событие .changePickupPoint")
            return
        }
        #expect(input === sut.coordinator)
    }

    @Test
    func placeOrderContinueToPaymentEvent_forwardsEventToModuleOutput() {
        var receivedEvents: [CartEvent] = []
        let sut = makeSUT(eventHandler: { receivedEvents.append($0) })
        sut.coordinator.start(with: sut.router)
        sut.coordinator.placeOrder(42)

        sut.composer.placeOrderEventHandler?(.onContinueToPayment)

        guard let event = receivedEvents.last else {
            Issue.record("Не получено событие .continueToPayment")
            return
        }
        guard case let .continueToPayment(input) = event else {
            Issue.record("Ожидалось событие .continueToPayment")
            return
        }
        #expect(input === sut.coordinator)
    }

    @Test
    func presentPickupPoints_presentsScreenAnimated() {
        let sut = makeSUT()
        sut.coordinator.start(with: sut.router)

        let pickupPointsVC = UIViewController()
        sut.coordinator.presentPickupPoints(viewController: pickupPointsVC)

        #expect(sut.router.presentedController === pickupPointsVC)
        #expect(sut.router.presentedAnimated == true)
    }

    @Test
    func showPayment_pushesScreenAnimated() {
        let sut = makeSUT()
        sut.coordinator.start(with: sut.router)

        let paymentVC = UIViewController()
        sut.coordinator.showPayment(viewController: paymentVC)

        #expect(sut.router.pushCalls.last?.viewController === paymentVC)
        #expect(sut.router.pushCalls.last?.animated == true)
    }

    @Test
    func closePayment_popsScreenAnimated() {
        let sut = makeSUT()
        sut.coordinator.start(with: sut.router)

        sut.coordinator.closePayment()

        #expect(sut.router.popCalls.last == true)
    }

    @Test
    func completePayment_buildsOrderConfirmationForGivenResult() {
        let sut = makeSUT()
        sut.coordinator.start(with: sut.router)

        let result: CartPaymentResult = .success(amount: 1200)
        sut.coordinator.completePayment(with: result)

        #expect(sut.composer.receivedPaymentResult != nil)
    }

    @Test
    func completePayment_pushesOrderConfirmationAnimated() {
        let sut = makeSUT()
        sut.coordinator.start(with: sut.router)

        sut.coordinator.completePayment(with: .success(amount: 1200))

        #expect(sut.router.pushCalls.count == 2)
        #expect(sut.router.pushCalls[1].viewController === sut.composer.orderConfirmationViewController)
        #expect(sut.router.pushCalls[1].animated == true)
    }

    @Test
    func completePayment_compactsNavigationStackToRootAndConfirmation() {
        let sut = makeSUT()
        sut.coordinator.start(with: sut.router)
        let cartRoot = sut.composer.cartViewController

        sut.coordinator.completePayment(with: .success(amount: 1200))

        #expect(sut.router.setStackCalls.count == 1)
        #expect(sut.router.setStackCalls[0].animated == false)
        #expect(sut.router.setStackCalls[0].viewControllers.count == 2)
        #expect(sut.router.setStackCalls[0].viewControllers[0] === cartRoot)
        #expect(sut.router.setStackCalls[0].viewControllers[1] === sut.composer.orderConfirmationViewController)
    }

    @Test
    func orderConfirmationReturnEvent_popsToRootAnimated() {
        let sut = makeSUT()
        sut.coordinator.start(with: sut.router)

        sut.coordinator.completePayment(with: .success(amount: 1200))
        sut.composer.orderConfirmationEventHandler?(.onReturnTap)

        #expect(sut.router.popToRootCalls.last == true)
    }

    @Test
    func completePayment_doesNothingWhenRootIsMissing() {
        let sut = makeSUT()

        sut.coordinator.completePayment(with: .success(amount: 1200))

        #expect(sut.router.pushCalls.isEmpty)
        #expect(sut.router.setStackCalls.isEmpty)
        #expect(sut.composer.receivedPaymentResult == nil)
    }
}

@MainActor
private extension CartCoordinatorTests {
    struct SUT {
        let coordinator: CartCoordinatingLogic<MockStackRouter>
        let composer: MockCartComposer
        let router: MockStackRouter
    }

    func makeSUT(eventHandler: @escaping (CartEvent) -> Void = { _ in }) -> SUT {
        let composer = MockCartComposer()
        let router = MockStackRouter()
        let coordinator = CartCoordinatingLogic<MockStackRouter>(
            composer: composer,
            eventHandler: eventHandler
        )
        return SUT(coordinator: coordinator, composer: composer, router: router)
    }
}

@MainActor
private final class MockCartComposer: CartComposing {
    let cartViewController = UIViewController()
    let placeOrderViewController = UIViewController()
    let orderConfirmationViewController = UIViewController()

    private(set) var requestedOrderIDs: [Int] = []
    private(set) var receivedPaymentResult: CartPaymentResult?

    var cartEventHandler: CartEventHandler?
    var placeOrderEventHandler: PlaceOrderEventHandler?
    var orderConfirmationEventHandler: OrderConfirmationEventHandler?

    func makeCartViewController(with eventHandler: @escaping CartEventHandler) -> UIViewController {
        cartEventHandler = eventHandler
        return cartViewController
    }

    func makePlaceOrderViewController(
        with orderID: Int,
        eventHandler: @escaping PlaceOrderEventHandler
    ) -> UIViewController {
        requestedOrderIDs.append(orderID)
        placeOrderEventHandler = eventHandler
        return placeOrderViewController
    }

    func makeOrderConfirmationViewController(
        paymentResult: CartPaymentResult,
        with eventHandler: @escaping OrderConfirmationEventHandler
    ) -> UIViewController {
        receivedPaymentResult = paymentResult
        orderConfirmationEventHandler = eventHandler
        return orderConfirmationViewController
    }
}

@MainActor
private final class MockStackRouter: UIViewController, StackRouting {
    struct PushCall {
        let viewController: UIViewController
        let animated: Bool
    }

    struct SetStackCall {
        let viewControllers: [UIViewController]
        let animated: Bool
    }

    var viewControllers: [UIViewController] = []

    private(set) var pushCalls: [PushCall] = []
    private(set) var popCalls: [Bool] = []
    private(set) var popToRootCalls: [Bool] = []
    private(set) var popToCalls: [(UIViewController, Bool)] = []
    private(set) var setStackCalls: [SetStackCall] = []

    private(set) var presentedController: UIViewController?
    private(set) var presentedAnimated: Bool = false

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
        popToRootCalls.append(animated)
        if let first = viewControllers.first {
            viewControllers = [first]
        }
        completion?()
    }

    func popTo(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        popToCalls.append((viewController, animated))
        completion?()
    }

    func setStack(_ viewControllers: [UIViewController], animated: Bool) {
        setStackCalls.append(SetStackCall(viewControllers: viewControllers, animated: animated))
        self.viewControllers = viewControllers
    }

    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        presentedController = viewControllerToPresent
        presentedAnimated = flag
        completion?()
    }
}
