import UIKit
import Testing
import HomeFeature
import CartFeature
@testable import Core
@testable import Demo_App_With_Coordinators

@MainActor
struct MainTabsCoordinatorTests {
    @Test
    func start_setsHomeAndCartTabsWithoutAnimation() {
        let sut = makeSUT()

        sut.coordinator.start(CoordinatorStartContext())

        #expect(sut.router.setItemsCalls.count == 1)
        #expect(sut.router.setItemsCalls[0].items.count == 2)
        #expect(sut.router.setItemsCalls[0].items[0].isWrapping(sut.composer.homeViewController))
        #expect(sut.router.setItemsCalls[0].items[1].isWrapping(sut.composer.cartViewController))
        #expect(sut.router.setItemsCalls[0].animated == false)
    }

    @Test
    func homePlaceOrder_selectsCartTabController() {
        let sut = makeSUT()
        sut.coordinator.start(CoordinatorStartContext())

        sut.composer.homeEventHandler?(.placeOrder(orderID: 42))

        #expect(sut.router.selectItemCalls.last?.isWrapping(sut.composer.cartViewController) == true)
    }

    @Test
    func homePlaceOrder_forwardsOrderIDToCartCoordinator() {
        let sut = makeSUT()
        sut.coordinator.start(CoordinatorStartContext())

        sut.composer.homeEventHandler?(.placeOrder(orderID: 42))

        #expect(sut.composer.mockCartNavigationInput.placeOrderCalls == [42])
    }

    @Test
    func homePickupPointsRequest_pushesPickupPointsInProvidedContext() {
        let sut = makeSUT()
        let context = MockNavigationStackContext()
        sut.coordinator.start(CoordinatorStartContext())

        sut.composer.homeEventHandler?(.pickupPointsRequested(context: context, onClose: {}))

        #expect(context.pushCalls.last?.viewController === sut.composer.pickupPointsViewController)
        #expect(context.pushCalls.last?.animated == true)
        #expect(sut.composer.pickupPointsEmbeddedInNavigationStack == true)
    }

    @Test
    func cartPaymentRequest_pushesPaymentInProvidedContext() {
        let sut = makeSUT()
        let context = MockNavigationStackContext()
        sut.coordinator.start(CoordinatorStartContext())

        sut.composer.cartEventHandler?(.paymentRequested(context: context, onComplete: { _ in }))

        #expect(context.pushCalls.last?.viewController === sut.composer.paymentViewController)
        #expect(context.pushCalls.last?.animated == true)
    }
}

@MainActor
private extension MainTabsCoordinatorTests {
    struct SUT {
        let coordinator: MainTabsCoordinatingLogic
        let composer: MockMainTabsComposer
        let router: MockTabRouter
    }

    func makeSUT() -> SUT {
        let composer = MockMainTabsComposer()
        let router = MockTabRouter()
        let coordinator = MainTabsCoordinatingLogic(router: router, composer: composer)
        return SUT(coordinator: coordinator, composer: composer, router: router)
    }
}

@MainActor
    private final class MockMainTabsComposer: MainTabsComposing {
        let homeViewController = UIViewController()
        let cartViewController = UIViewController()
        let pickupPointsViewController = UIViewController()
        let paymentViewController = UIViewController()
        let mockCartNavigationInput = MockCartNavigationInput()

        var homeEventHandler: ((HomeNavigationOutputEvent) -> Void)?
        var cartEventHandler: ((CartNavigationOutputEvent) -> Void)?
        var pickupPointsEmbeddedInNavigationStack: Bool?

        func makeViewController(for route: MainTabsRoute) -> UIViewController {
            switch route {
            case .home(let onEvent):
                homeEventHandler = onEvent
                return homeViewController
            case let .cart(onCreated, onEvent):
                cartEventHandler = onEvent
                onCreated(mockCartNavigationInput)
                return cartViewController
            case let .pickupPoints(embeddedInNavigationStack, _):
                pickupPointsEmbeddedInNavigationStack = embeddedInNavigationStack
                return pickupPointsViewController
            case .payment:
                return paymentViewController
            }
        }
    }

    @MainActor
    private final class MockCartNavigationInput: CartNavigationInput {
        private(set) var placeOrderCalls: [Int] = []

        func placeOrder(_ orderID: Int) {
            placeOrderCalls.append(orderID)
        }
    }

    @MainActor
    private final class MockNavigationStackContext: NavigationStackContext {
        struct Call {
            let viewController: UIViewController
            let animated: Bool
        }

        private(set) var pushCalls: [Call] = []
        private(set) var presentCalls: [Call] = []
        private(set) var popCalls: [Bool] = []
        private(set) var dismissCalls: [Bool] = []

        func push(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
            pushCalls.append(Call(viewController: viewController, animated: animated))
            completion?()
        }

        func present(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
            presentCalls.append(Call(viewController: viewController, animated: animated))
            completion?()
        }

        func pop(animated: Bool, completion: (() -> Void)?) {
            popCalls.append(animated)
            completion?()
        }

        func dismiss(animated: Bool, completion: (() -> Void)?) {
            dismissCalls.append(animated)
            completion?()
        }
    }

@MainActor
private final class MockTabRouter: TabsNavigation {
    struct SetItemsCall {
        let items: [RouterItem]
        let animated: Bool
    }

    var selectedIndex: Int = 0
    var selectedItem: RouterItem?

    private(set) var setItemsCalls: [SetItemsCall] = []
    private(set) var selectTabCalls: [Int] = []
    private(set) var selectItemCalls: [RouterItem] = []

    func setItems(_ items: [RouterItem], animated: Bool) {
        setItemsCalls.append(SetItemsCall(items: items, animated: animated))
    }

    func selectTab(at index: Int) {
        selectTabCalls.append(index)
        selectedIndex = index
    }

    func selectItem(_ item: RouterItem) {
        selectItemCalls.append(item)
        selectedItem = item
    }

    func present(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {}
    func dismiss(animated: Bool, completion: (() -> Void)?) {}
}
