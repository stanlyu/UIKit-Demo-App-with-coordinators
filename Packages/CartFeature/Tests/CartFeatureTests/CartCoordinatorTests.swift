import UIKit
import Testing
@testable import Core
@testable import CartFeature

@MainActor
struct CartCoordinatorTests {
    @Test
    func start_setsCartRootWithoutAnimation() {
        let sut = makeSUT()

        sut.coordinator.start(CoordinatorStartContext())

        #expect(sut.router.setRootCalls.count == 1)
        #expect(sut.router.setRootCalls[0].item.isWrapping(sut.composer.cartViewController))
        #expect(sut.router.setRootCalls[0].animated == false)
    }

    @Test
    func placeOrder_requestsScreenForGivenOrderID() {
        let sut = makeSUT()
        sut.coordinator.start(CoordinatorStartContext())

        sut.coordinator.placeOrder(42)

        #expect(sut.composer.requestedOrderIDs == [42])
    }

    @Test
    func placeOrder_popsToRootWithoutAnimationBeforePush() {
        let sut = makeSUT()
        sut.coordinator.start(CoordinatorStartContext())

        sut.coordinator.placeOrder(42)

        #expect(sut.router.popToRootCalls == [false])
    }

    @Test
    func placeOrder_pushesPlaceOrderScreenAnimated() {
        let sut = makeSUT()
        sut.coordinator.start(CoordinatorStartContext())

        sut.coordinator.placeOrder(42)

        #expect(sut.router.pushCalls.count == 1)
        #expect(sut.router.pushCalls[0].item.isWrapping(sut.composer.placeOrderViewController))
        #expect(sut.router.pushCalls[0].animated == true)
    }

    @Test
    func placeOrderBackEvent_popsCurrentScreen() {
        let sut = makeSUT()
        sut.coordinator.start(CoordinatorStartContext())
        sut.coordinator.placeOrder(42)

        sut.composer.placeOrderEventHandler?(.onBackTap)

        #expect(sut.router.popCalls == [true])
    }

    @Test
    func changePickupPointEvent_presentsPickupPointsScreen() {
        let sut = makeSUT()
        sut.coordinator.start(CoordinatorStartContext())
        sut.coordinator.placeOrder(42)

        sut.composer.placeOrderEventHandler?(.onChangePickupPointTap)

        #expect(sut.router.presentedItem?.isWrapping(sut.composer.pickupPointsViewController) == true)
        #expect(sut.router.presentedAnimated == true)
    }

    @Test
    func pickupPointsOnClose_dismissesPresentedScreen() {
        let sut = makeSUT()
        sut.coordinator.start(CoordinatorStartContext())
        sut.coordinator.placeOrder(42)
        sut.composer.placeOrderEventHandler?(.onChangePickupPointTap)

        sut.composer.pickupPointsOnClose?()

        #expect(sut.router.dismissCalls == [true])
    }

    @Test
    func continueToPaymentEvent_pushesPaymentScreen() {
        let sut = makeSUT()
        sut.coordinator.start(CoordinatorStartContext())
        sut.coordinator.placeOrder(42)

        sut.composer.placeOrderEventHandler?(.onContinueToPayment)

        #expect(sut.router.pushCalls.count == 2)
        #expect(sut.router.pushCalls[1].item.isWrapping(sut.composer.paymentViewController) == true)
        #expect(sut.router.pushCalls[1].animated == true)
    }

    @Test
    func paymentCompletionWithNil_popsPaymentScreen() {
        let sut = makeSUT()
        sut.coordinator.start(CoordinatorStartContext())
        sut.coordinator.placeOrder(42)
        sut.composer.placeOrderEventHandler?(.onContinueToPayment)

        sut.composer.paymentOnComplete?(nil)

        #expect(sut.router.popCalls.last == true)
    }

    @Test
    func paymentCompletionWithResult_buildsOrderConfirmationForGivenResult() {
        let sut = makeSUT()
        sut.coordinator.start(CoordinatorStartContext())
        sut.coordinator.placeOrder(42)
        sut.composer.placeOrderEventHandler?(.onContinueToPayment)

        let result: CartPaymentResult = .success(amount: 1200)
        sut.composer.paymentOnComplete?(result)

        #expect(sut.composer.receivedPaymentResult != nil)
    }

    @Test
    func paymentCompletionWithResult_pushesOrderConfirmationAnimated() {
        let sut = makeSUT()
        sut.coordinator.start(CoordinatorStartContext())
        sut.coordinator.placeOrder(42)
        sut.composer.placeOrderEventHandler?(.onContinueToPayment)

        sut.composer.paymentOnComplete?(.success(amount: 1200))

        #expect(sut.router.pushCalls.count == 2)
        #expect(sut.router.pushCalls[1].item.isWrapping(sut.composer.orderConfirmationViewController))
        #expect(sut.router.pushCalls[1].animated == true)
    }

    @Test
    func paymentCompletionWithResult_compactsNavigationStackToRootAndConfirmation() {
        let sut = makeSUT()
        sut.coordinator.start(CoordinatorStartContext())
        let cartRoot = sut.composer.cartViewController

        sut.coordinator.placeOrder(42)
        sut.composer.placeOrderEventHandler?(.onContinueToPayment)
        sut.composer.paymentOnComplete?(.success(amount: 1200))

        #expect(sut.router.setStackCalls.count == 1)
        #expect(sut.router.setStackCalls[0].animated == false)
        #expect(sut.router.setStackCalls[0].items.count == 2)
        #expect(sut.router.setStackCalls[0].items[0].isWrapping(cartRoot))
        #expect(sut.router.setStackCalls[0].items[1].isWrapping(sut.composer.orderConfirmationViewController))
    }

    @Test
    func orderConfirmationReturnEvent_popsToRootAnimated() {
        let sut = makeSUT()
        sut.coordinator.start(CoordinatorStartContext())

        sut.coordinator.placeOrder(42)
        sut.composer.placeOrderEventHandler?(.onContinueToPayment)
        sut.composer.paymentOnComplete?(.success(amount: 1200))
        sut.composer.orderConfirmationEventHandler?(.onReturnTap)

        #expect(sut.router.popToRootCalls.last == true)
    }

}

@MainActor
private extension CartCoordinatorTests {
    struct SUT {
        let coordinator: CartCoordinatingLogic
        let composer: MockCartComposer
        let router: MockStackRouter
        let output: CartOutputSpy
    }

    func makeSUT() -> SUT {
        let composer = MockCartComposer()
        let router = MockStackRouter()
        let output = CartOutputSpy()
        let coordinator = CartCoordinatingLogic(router: router, composer: composer, onEvent: { event in
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
    let pickupPointsViewController = UIViewController()
    let paymentViewController = UIViewController()

    private(set) var requestedOrderIDs: [Int] = []
    private(set) var receivedPaymentResult: CartPaymentResult?

    var placeOrderEventHandler: PlaceOrderEventHandler?
    var orderConfirmationEventHandler: OrderConfirmationEventHandler?
    var pickupPointsOnClose: (() -> Void)?
    var paymentOnComplete: ((CartPaymentResult?) -> Void)?

    func makeViewController(for route: CartRoute) -> UIViewController {
        switch route {
        case .cart(_):
            return cartViewController
        case .placeOrder(let orderID, let eventHandler):
            requestedOrderIDs.append(orderID)
            placeOrderEventHandler = eventHandler
            return placeOrderViewController
        case .orderConfirmation(let paymentResult, let eventHandler):
            receivedPaymentResult = paymentResult
            orderConfirmationEventHandler = eventHandler
            return orderConfirmationViewController
        case .pickupPoints(let onClose):
            pickupPointsOnClose = onClose
            return pickupPointsViewController
        case .payment(let onComplete):
            paymentOnComplete = onComplete
            return paymentViewController
        }
    }
}

@MainActor
private final class CartOutputSpy {
    func handle(_ event: CartNavigationOutputEvent) {
        switch event {}
    }
}

@MainActor
private final class MockStackRouter: StackNavigation {
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

    struct SetRootCall {
        let item: RouterItem
        let animated: Bool
    }
    private(set) var setRootCalls: [SetRootCall] = []

    func setRoot(_ item: RouterItem, animated: Bool) {
        setRootCalls.append(SetRootCall(item: item, animated: animated))
        items = [item]
    }

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
