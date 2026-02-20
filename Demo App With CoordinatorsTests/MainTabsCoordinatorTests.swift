import UIKit
import Testing
import HomeFeature
import CartFeature
import DeliveryFeature
import PaymentFeature
@testable import Core
@testable import Demo_App_With_Coordinators

@MainActor
struct MainTabsCoordinatorTests {
    @Test
    func start_setsHomeAndCartTabsWithoutAnimation() {
        let sut = makeSUT()

        sut.coordinator.start(with: sut.router)

        #expect(sut.router.setViewControllersCalls.count == 1)
        #expect(sut.router.setViewControllersCalls[0].viewControllers.count == 2)
        #expect(sut.router.setViewControllersCalls[0].viewControllers[0] === sut.composer.homeViewController)
        #expect(sut.router.setViewControllersCalls[0].viewControllers[1] === sut.composer.cartViewController)
        #expect(sut.router.setViewControllersCalls[0].animated == false)
    }

    @Test
    func homePlaceOrder_selectsCartTabController() {
        let sut = makeSUT()
        sut.coordinator.start(with: sut.router)

        sut.composer.homeEventHandler?(.placeOrder(42))

        #expect(sut.router.selectViewControllerCalls.last === sut.composer.cartViewController)
    }

    @Test
    func homePlaceOrder_forwardsOrderIDToCartCoordinator() {
        let sut = makeSUT()
        sut.coordinator.start(with: sut.router)

        sut.composer.homeEventHandler?(.placeOrder(42))

        #expect(sut.composer.cartInput.placeOrderCalls == [42])
    }

    @Test
    func homeSelectPickupPoint_requestsEmbeddedPickupPointsModule() {
        let sut = makeSUT()
        sut.coordinator.start(with: sut.router)
        let homeInput = MockHomeInput()

        sut.composer.homeEventHandler?(.selectPickupPoint(homeInput))

        #expect(sut.composer.pickupPointsEmbeddedRequests == [true])
    }

    @Test
    func homeSelectPickupPoint_forwardsModuleToHomeInput() {
        let sut = makeSUT()
        sut.coordinator.start(with: sut.router)
        let homeInput = MockHomeInput()

        sut.composer.homeEventHandler?(.selectPickupPoint(homeInput))

        #expect(homeInput.presentCalls.last === sut.composer.embeddedPickupPointsViewController)
    }

    @Test
    func cartChangePickupPoint_requestsNonEmbeddedPickupPointsModule() {
        let sut = makeSUT()
        sut.coordinator.start(with: sut.router)

        sut.composer.cartEventHandler?(.changePickupPoint(sut.composer.cartInput))

        #expect(sut.composer.pickupPointsEmbeddedRequests == [false])
    }

    @Test
    func cartChangePickupPoint_forwardsModuleToCartInput() {
        let sut = makeSUT()
        sut.coordinator.start(with: sut.router)

        sut.composer.cartEventHandler?(.changePickupPoint(sut.composer.cartInput))

        #expect(sut.composer.cartInput.presentPickupPointsCalls.last === sut.composer.standalonePickupPointsViewController)
    }

    @Test
    func cartContinueToPayment_requestsPaymentScreen() {
        let sut = makeSUT()
        sut.coordinator.start(with: sut.router)

        sut.composer.cartEventHandler?(.continueToPayment(sut.composer.cartInput))

        #expect(sut.composer.makePaymentViewControllerCallsCount == 1)
    }

    @Test
    func cartContinueToPayment_forwardsPaymentScreenToCartInput() {
        let sut = makeSUT()
        sut.coordinator.start(with: sut.router)

        sut.composer.cartEventHandler?(.continueToPayment(sut.composer.cartInput))

        #expect(sut.composer.cartInput.showPaymentCalls.last === sut.composer.paymentViewController)
    }

    @Test
    func paymentCancelled_closesPaymentInCartCoordinator() {
        let sut = makeSUT()
        sut.coordinator.start(with: sut.router)
        sut.composer.cartEventHandler?(.continueToPayment(sut.composer.cartInput))

        sut.composer.paymentEventHandler?(.cancelled)

        #expect(sut.composer.cartInput.closePaymentCallsCount == 1)
    }

    @Test
    func paymentCompleted_convertsAndForwardsResultToCartCoordinator() {
        let sut = makeSUT()
        sut.coordinator.start(with: sut.router)
        sut.composer.convertedCartPaymentResultToReturn = .failure(amount: 777, error: .networkUnavailable)
        sut.composer.cartEventHandler?(.continueToPayment(sut.composer.cartInput))

        let paymentResult = PaymentResult.failure(amount: 1200, error: .processingTimeout)
        sut.composer.paymentEventHandler?(.completed(paymentResult))

        #expect(sut.composer.convertedPaymentResults.count == 1)
        #expect(paymentResultEquals(sut.composer.convertedPaymentResults[0], paymentResult))
        #expect(sut.composer.cartInput.completePaymentCalls.count == 1)
        #expect(cartPaymentResultEquals(sut.composer.cartInput.completePaymentCalls[0], .failure(amount: 777, error: .networkUnavailable)))
    }
}

@MainActor
private extension MainTabsCoordinatorTests {
    struct SUT {
        let coordinator: MainTabsCoordinatingLogic<MockTabRouter>
        let composer: MockMainTabsComposer
        let router: MockTabRouter
    }

    func makeSUT() -> SUT {
        let composer = MockMainTabsComposer()
        let router = MockTabRouter()
        let coordinator = MainTabsCoordinatingLogic<MockTabRouter>(composer: composer)
        return SUT(coordinator: coordinator, composer: composer, router: router)
    }

    func paymentResultEquals(_ lhs: PaymentResult, _ rhs: PaymentResult) -> Bool {
        switch (lhs, rhs) {
        case let (.success(lhsAmount), .success(rhsAmount)):
            return lhsAmount == rhsAmount
        case let (.failure(lhsAmount, lhsError), .failure(rhsAmount, rhsError)):
            return lhsAmount == rhsAmount && lhsError == rhsError
        default:
            return false
        }
    }

    func cartPaymentResultEquals(_ lhs: CartPaymentResult, _ rhs: CartPaymentResult) -> Bool {
        switch (lhs, rhs) {
        case let (.success(lhsAmount), .success(rhsAmount)):
            return lhsAmount == rhsAmount
        case let (.failure(lhsAmount, lhsError), .failure(rhsAmount, rhsError)):
            return lhsAmount == rhsAmount && lhsError == rhsError
        default:
            return false
        }
    }
}

@MainActor
private final class MockMainTabsComposer: MainTabsComposing {
    let homeViewController = UIViewController()
    let cartViewController = UIViewController()
    let embeddedPickupPointsViewController = UIViewController()
    let standalonePickupPointsViewController = UIViewController()
    let paymentViewController = UIViewController()

    let cartInput = MockCartInput()

    var homeEventHandler: ((HomeEvent) -> Void)?
    var cartEventHandler: ((CartEvent) -> Void)?
    var paymentEventHandler: ((PaymentEvent) -> Void)?

    private(set) var pickupPointsEmbeddedRequests: [Bool] = []
    private(set) var makePaymentViewControllerCallsCount: Int = 0
    private(set) var convertedPaymentResults: [PaymentResult] = []

    var convertedCartPaymentResultToReturn: CartPaymentResult = .success(amount: 777)

    func makeHomeViewController(with eventHandler: @escaping (HomeEvent) -> Void) -> UIViewController {
        homeEventHandler = eventHandler
        return homeViewController
    }

    func makeCartViewController(with eventHandler: @escaping (CartEvent) -> Void) -> CartModule {
        cartEventHandler = eventHandler
        return (cartViewController, cartInput)
    }

    func makePickupPointsViewController(embeddedInNavigationStack: Bool) -> UIViewController {
        pickupPointsEmbeddedRequests.append(embeddedInNavigationStack)
        return embeddedInNavigationStack ? embeddedPickupPointsViewController : standalonePickupPointsViewController
    }

    func makePaymentViewController(with eventHandler: @escaping (PaymentEvent) -> Void) -> UIViewController {
        makePaymentViewControllerCallsCount += 1
        paymentEventHandler = eventHandler
        return paymentViewController
    }

    func makeCartPaymentResult(from paymentResult: PaymentResult) -> CartPaymentResult {
        convertedPaymentResults.append(paymentResult)
        return convertedCartPaymentResultToReturn
    }

    func makeCartPaymentError(from paymentError: PaymentError) -> CartPaymentError {
        switch paymentError {
        case .insufficientFunds:
            return .insufficientFunds
        case .cardExpired:
            return .cardExpired
        case .bankDeclined:
            return .bankDeclined
        case .networkUnavailable:
            return .networkUnavailable
        case .processingTimeout:
            return .processingTimeout
        }
    }
}

@MainActor
private final class MockHomeInput: HomeInput {
    private(set) var presentCalls: [UIViewController] = []

    func presentPickupPoints(module: UIViewController) {
        presentCalls.append(module)
    }
}

@MainActor
private final class MockCartInput: CartInput {
    private(set) var presentPickupPointsCalls: [UIViewController] = []
    private(set) var showPaymentCalls: [UIViewController] = []
    private(set) var closePaymentCallsCount: Int = 0
    private(set) var placeOrderCalls: [Int] = []
    private(set) var completePaymentCalls: [CartPaymentResult] = []

    func presentPickupPoints(viewController: UIViewController) {
        presentPickupPointsCalls.append(viewController)
    }

    func showPayment(viewController: UIViewController) {
        showPaymentCalls.append(viewController)
    }

    func closePayment() {
        closePaymentCallsCount += 1
    }

    func placeOrder(_ orderID: Int) {
        placeOrderCalls.append(orderID)
    }

    func completePayment(with result: CartPaymentResult) {
        completePaymentCalls.append(result)
    }
}

@MainActor
private final class MockTabRouter: UIViewController, TabRouting {
    struct SetViewControllersCall {
        let viewControllers: [UIViewController]
        let animated: Bool
    }

    var selectedIndex: Int = 0
    var selectedViewController: UIViewController?

    private(set) var setViewControllersCalls: [SetViewControllersCall] = []
    private(set) var selectTabCalls: [Int] = []
    private(set) var selectViewControllerCalls: [UIViewController] = []

    func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        setViewControllersCalls.append(SetViewControllersCall(viewControllers: viewControllers, animated: animated))
    }

    func selectTab(at index: Int) {
        selectTabCalls.append(index)
        selectedIndex = index
    }

    func selectViewController(_ viewController: UIViewController) {
        selectViewControllerCalls.append(viewController)
        selectedViewController = viewController
    }
}
