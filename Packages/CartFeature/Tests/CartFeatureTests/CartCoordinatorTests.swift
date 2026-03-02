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
    func changePickupPointEvent_requestsPickupPointsScreen() {
        let sut = makeSUT()
        sut.coordinator.start(with: sut.router)
        sut.coordinator.placeOrder(42)

        sut.composer.placeOrderEventHandler?(.onChangePickupPointTap)

        #expect(sut.composer.makePickupPointsViewControllerCallsCount == 1)
    }

    @Test
    func changePickupPointEvent_presentsPickupPointsScreenAnimated() {
        let sut = makeSUT()
        sut.coordinator.start(with: sut.router)
        sut.coordinator.placeOrder(42)

        sut.composer.placeOrderEventHandler?(.onChangePickupPointTap)

        #expect(sut.router.presentedItem?.viewController === sut.composer.pickupPointsViewController)
        #expect(sut.router.presentedAnimated == true)
    }

    @Test
    func continueToPaymentEvent_requestsPaymentScreen() {
        let sut = makeSUT()
        sut.coordinator.start(with: sut.router)
        sut.coordinator.placeOrder(42)

        sut.composer.placeOrderEventHandler?(.onContinueToPayment)

        #expect(sut.composer.makePaymentViewControllerCallsCount == 1)
    }

    @Test
    func continueToPaymentEvent_pushesPaymentScreenAnimated() {
        let sut = makeSUT()
        sut.coordinator.start(with: sut.router)
        sut.coordinator.placeOrder(42)

        sut.composer.placeOrderEventHandler?(.onContinueToPayment)

        #expect(sut.router.pushCalls.count == 3)
        #expect(sut.router.pushCalls[2].item.viewController === sut.composer.paymentViewController)
        #expect(sut.router.pushCalls[2].animated == true)
    }

    @Test
    func paymentCompletionWithNil_popsPaymentScreen() {
        let sut = makeSUT()
        sut.coordinator.start(with: sut.router)
        sut.coordinator.placeOrder(42)
        sut.composer.placeOrderEventHandler?(.onContinueToPayment)

        sut.composer.paymentOnComplete?(nil)

        #expect(sut.router.popCalls.last == true)
    }

    @Test
    func paymentCompletionWithResult_buildsOrderConfirmationForGivenResult() {
        let sut = makeSUT()
        sut.coordinator.start(with: sut.router)
        sut.coordinator.placeOrder(42)
        sut.composer.placeOrderEventHandler?(.onContinueToPayment)

        let result: CartPaymentResult = .success(amount: 1200)
        sut.composer.paymentOnComplete?(result)

        #expect(sut.composer.receivedPaymentResult != nil)
    }

    @Test
    func paymentCompletionWithResult_pushesOrderConfirmationAnimated() {
        let sut = makeSUT()
        sut.coordinator.start(with: sut.router)
        sut.coordinator.placeOrder(42)
        sut.composer.placeOrderEventHandler?(.onContinueToPayment)

        sut.composer.paymentOnComplete?(.success(amount: 1200))

        #expect(sut.router.pushCalls.count == 4)
        #expect(sut.router.pushCalls[3].item.viewController === sut.composer.orderConfirmationViewController)
        #expect(sut.router.pushCalls[3].animated == true)
    }

    @Test
    func paymentCompletionWithResult_compactsNavigationStackToRootAndConfirmation() {
        let sut = makeSUT()
        sut.coordinator.start(with: sut.router)
        let cartRoot = sut.composer.cartViewController

        sut.coordinator.placeOrder(42)
        sut.composer.placeOrderEventHandler?(.onContinueToPayment)
        sut.composer.paymentOnComplete?(.success(amount: 1200))

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
        sut.composer.paymentOnComplete?(.success(amount: 1200))
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
    }

    func makeSUT() -> SUT {
        let composer = MockCartComposer()
        let router = MockStackRouter()
        let coordinator = CartCoordinatingLogic<MockStackRouter>(composer: composer)
        return SUT(coordinator: coordinator, composer: composer, router: router)
    }
}

@MainActor
private final class MockCartComposer: CartComposing {
    let cartViewController = UIViewController()
    let placeOrderViewController = UIViewController()
    let pickupPointsViewController = UIViewController()
    let paymentViewController = UIViewController()
    let orderConfirmationViewController = UIViewController()

    private(set) var requestedOrderIDs: [Int] = []
    private(set) var receivedPaymentResult: CartPaymentResult?
    private(set) var makePickupPointsViewControllerCallsCount = 0
    private(set) var makePaymentViewControllerCallsCount = 0

    var placeOrderEventHandler: PlaceOrderEventHandler?
    var orderConfirmationEventHandler: OrderConfirmationEventHandler?

    var paymentOnComplete: ((CartPaymentResult?) -> Void)?

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
        case .pickupPoints:
            makePickupPointsViewControllerCallsCount += 1
            return pickupPointsViewController
        case .payment(let onComplete):
            makePaymentViewControllerCallsCount += 1
            paymentOnComplete = onComplete
            return paymentViewController
        }
    }
}

@MainActor
private final class MockStackRouter: StackRouting {
    func extractContent() -> UIViewController { return UIViewController() }

    struct PushCall {
        let item: ContainerItem
        let animated: Bool
    }

    struct SetStackCall {
        let items: [ContainerItem]
        let animated: Bool
    }

    var items: [ContainerItem] = []

    private(set) var pushCalls: [PushCall] = []
    private(set) var popCalls: [Bool] = []
    private(set) var popToRootCalls: [Bool] = []
    private(set) var popToCalls: [(ContainerItem, Bool)] = []
    private(set) var setStackCalls: [SetStackCall] = []
    private(set) var presentedItem: ContainerItem?
    private(set) var presentedAnimated: Bool = false

    func push(_ item: ContainerItem, animated: Bool, completion: (() -> Void)?) {
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

    func popTo(_ item: ContainerItem, animated: Bool, completion: (() -> Void)?) {
        popToCalls.append((item, animated))
        completion?()
    }

    func setStack(_ items: [ContainerItem], animated: Bool) {
        setStackCalls.append(SetStackCall(items: items, animated: animated))
        self.items = items
    }

    func present(_ item: ContainerItem, animated: Bool, completion: (() -> Void)?) {
        presentedItem = item
        presentedAnimated = animated
        completion?()
    }
    
    func dismiss(animated: Bool, completion: (() -> Void)?) {}
}
