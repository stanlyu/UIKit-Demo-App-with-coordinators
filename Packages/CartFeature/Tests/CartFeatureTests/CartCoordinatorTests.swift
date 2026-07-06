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
        #expect(sut.router.pushCalls[0].item.viewController === sut.composer.cartViewController)
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
        #expect(sut.router.pushCalls[1].item.viewController === sut.composer.placeOrderViewController)
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
    func changePickupPointEvent_forwardsPickupPointsRequestToModuleOutput() {
        let sut = makeSUT()
        sut.coordinator.start(with: sut.router)
        sut.coordinator.placeOrder(42)

        sut.composer.placeOrderEventHandler?(.onChangePickupPointTap)

        #expect(sut.output.pickupPointsContext != nil)
    }

    @Test
    func pickupPointsContext_presentsExternalScreenAnimated() {
        let sut = makeSUT()
        sut.coordinator.start(with: sut.router)
        sut.coordinator.placeOrder(42)

        sut.composer.placeOrderEventHandler?(.onChangePickupPointTap)
        let pickupPointsViewController = UIViewController()
        sut.output.pickupPointsContext?.present(pickupPointsViewController, animated: true)

        #expect(sut.router.presentedItem?.viewController === pickupPointsViewController)
        #expect(sut.router.presentedAnimated == true)
    }

    @Test
    func pickupPointsOnClose_dismissesPresentedScreen() {
        let sut = makeSUT()
        sut.coordinator.start(with: sut.router)
        sut.coordinator.placeOrder(42)

        sut.composer.placeOrderEventHandler?(.onChangePickupPointTap)
        sut.output.pickupPointsOnClose?()

        #expect(sut.router.dismissCalls == [true])
    }

    @Test
    func continueToPaymentEvent_forwardsPaymentRequestToModuleOutput() {
        let sut = makeSUT()
        sut.coordinator.start(with: sut.router)
        sut.coordinator.placeOrder(42)

        sut.composer.placeOrderEventHandler?(.onContinueToPayment)

        #expect(sut.output.paymentContext != nil)
    }

    @Test
    func paymentContext_pushesExternalScreenAnimated() {
        let sut = makeSUT()
        sut.coordinator.start(with: sut.router)
        sut.coordinator.placeOrder(42)

        sut.composer.placeOrderEventHandler?(.onContinueToPayment)
        let paymentViewController = UIViewController()
        sut.output.paymentContext?.push(paymentViewController, animated: true)

        #expect(sut.router.pushCalls.count == 3)
        #expect(sut.router.pushCalls[2].item.viewController === paymentViewController)
        #expect(sut.router.pushCalls[2].animated == true)
    }

    @Test
    func paymentCompletionWithNil_popsPaymentScreen() {
        let sut = makeSUT()
        sut.coordinator.start(with: sut.router)
        sut.coordinator.placeOrder(42)
        sut.composer.placeOrderEventHandler?(.onContinueToPayment)

        sut.output.paymentOnComplete?(nil)

        #expect(sut.router.popCalls.last == true)
    }

    @Test
    func paymentCompletionWithResult_buildsOrderConfirmationForGivenResult() {
        let sut = makeSUT()
        sut.coordinator.start(with: sut.router)
        sut.coordinator.placeOrder(42)
        sut.composer.placeOrderEventHandler?(.onContinueToPayment)

        let result: CartPaymentResult = .success(amount: 1200)
        sut.output.paymentOnComplete?(result)

        #expect(sut.composer.receivedPaymentResult != nil)
    }

    @Test
    func paymentCompletionWithResult_pushesOrderConfirmationAnimated() {
        let sut = makeSUT()
        sut.coordinator.start(with: sut.router)
        sut.coordinator.placeOrder(42)
        sut.composer.placeOrderEventHandler?(.onContinueToPayment)

        sut.output.paymentOnComplete?(.success(amount: 1200))

        #expect(sut.router.pushCalls.count == 3)
        #expect(sut.router.pushCalls[2].item.viewController === sut.composer.orderConfirmationViewController)
        #expect(sut.router.pushCalls[2].animated == true)
    }

    @Test
    func paymentCompletionWithResult_compactsNavigationStackToRootAndConfirmation() {
        let sut = makeSUT()
        sut.coordinator.start(with: sut.router)
        let cartRoot = sut.composer.cartViewController

        sut.coordinator.placeOrder(42)
        sut.composer.placeOrderEventHandler?(.onContinueToPayment)
        sut.output.paymentOnComplete?(.success(amount: 1200))

        #expect(sut.router.setStackCalls.count == 1)
        #expect(sut.router.setStackCalls[0].animated == false)
        #expect(sut.router.setStackCalls[0].items.count == 2)
        #expect(sut.router.setStackCalls[0].items[0].viewController === cartRoot)
        #expect(sut.router.setStackCalls[0].items[1].viewController === sut.composer.orderConfirmationViewController)
    }

    @Test
    func orderConfirmationReturnEvent_popsToRootAnimated() {
        let sut = makeSUT()
        sut.coordinator.start(with: sut.router)

        sut.coordinator.placeOrder(42)
        sut.composer.placeOrderEventHandler?(.onContinueToPayment)
        sut.output.paymentOnComplete?(.success(amount: 1200))
        sut.composer.orderConfirmationEventHandler?(.onReturnTap)

        #expect(sut.router.popToRootCalls.last == true)
    }

}

@MainActor
private extension CartCoordinatorTests {
    struct SUT {
        let coordinator: CartCoordinatingLogic<MockStackRouter>
        let composer: MockCartComposer
        let router: MockStackRouter
        let output: CartOutputSpy
    }

    func makeSUT() -> SUT {
        let composer = MockCartComposer()
        let router = MockStackRouter()
        let output = CartOutputSpy()
        let coordinator = CartCoordinatingLogic<MockStackRouter>(composer: composer, onEvent: { event in
            output.handle(event)
        })
        return SUT(coordinator: coordinator, composer: composer, router: router, output: output)
    }
}

@MainActor
private final class MockCartComposer: CartComposing {
    let cartViewController = UIViewController()
    let placeOrderViewController = UIViewController()
    let orderConfirmationViewController = UIViewController()

    private(set) var requestedOrderIDs: [Int] = []
    private(set) var receivedPaymentResult: CartPaymentResult?

    var placeOrderEventHandler: PlaceOrderEventHandler?
    var orderConfirmationEventHandler: OrderConfirmationEventHandler?

    func makeViewController(for route: CartRoute) -> UIViewController {
        switch route {
        case .cart(let eventHandler):
            return cartViewController
        case .placeOrder(let orderID, let eventHandler):
            requestedOrderIDs.append(orderID)
            placeOrderEventHandler = eventHandler
            return placeOrderViewController
        case .orderConfirmation(let paymentResult, let eventHandler):
            receivedPaymentResult = paymentResult
            orderConfirmationEventHandler = eventHandler
            return orderConfirmationViewController
        }
    }
}

@MainActor
private final class CartOutputSpy {
    private(set) var pickupPointsContext: (any NavigationStackContext)?
    private(set) var pickupPointsOnClose: (() -> Void)?
    private(set) var paymentContext: (any NavigationStackContext)?
    private(set) var paymentOnComplete: ((CartPaymentResult?) -> Void)?

    func handle(_ event: CartNavigationOutputEvent) {
        switch event {
        case let .pickupPointsRequested(context, onClose):
            pickupPointsContext = context
            pickupPointsOnClose = onClose
        case let .paymentRequested(context, onComplete):
            paymentContext = context
            paymentOnComplete = onComplete
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

    struct SetStackCall {
        let items: [RouterItem]
        let animated: Bool
    }

    var items: [RouterItem] = []

    private(set) var pushCalls: [PushCall] = []
    private(set) var popCalls: [Bool] = []
    private(set) var popToRootCalls: [Bool] = []
    private(set) var popToCalls: [(RouterItem, Bool)] = []
    private(set) var setStackCalls: [SetStackCall] = []
    private(set) var presentedItem: RouterItem?
    private(set) var presentedAnimated: Bool = false
    private(set) var dismissCalls: [Bool] = []

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
        popToRootCalls.append(animated)
        if let first = items.first {
            items = [first]
        }
        completion?()
    }

    func popTo(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        popToCalls.append((item, animated))
        completion?()
    }

    func setStack(_ items: [RouterItem], animated: Bool) {
        setStackCalls.append(SetStackCall(items: items, animated: animated))
        self.items = items
    }

    func present(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        presentedItem = item
        presentedAnimated = animated
        completion?()
    }
    
    func dismiss(animated: Bool, completion: (() -> Void)?) {
        dismissCalls.append(animated)
        completion?()
    }
}
