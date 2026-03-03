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

        sut.coordinator.start(with: sut.router)

        #expect(sut.router.setItemsCalls.count == 1)
        #expect(sut.router.setItemsCalls[0].items.count == 2)
        #expect(sut.router.setItemsCalls[0].items[0].viewController === sut.composer.homeViewController)
        #expect(sut.router.setItemsCalls[0].items[1].viewController === sut.composer.cartViewController)
        #expect(sut.router.setItemsCalls[0].animated == false)
    }

    @Test
    func homePlaceOrder_selectsCartTabController() {
        let sut = makeSUT()
        sut.coordinator.start(with: sut.router)

        sut.composer.homeEventHandler?(.placeOrder(42))

        #expect(sut.router.selectItemCalls.last?.viewController === sut.composer.cartViewController)
    }

    @Test
    func homePlaceOrder_forwardsOrderIDToCartCoordinator() {
        let sut = makeSUT()
        sut.coordinator.start(with: sut.router)

        sut.composer.homeEventHandler?(.placeOrder(42))

        #expect(sut.composer.mockCartInput.placeOrderCalls == [42])
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
}

@MainActor
private final class MockMainTabsComposer: MainTabsComposing {
    let homeViewController = UIViewController()
    let cartViewController = UIViewController()
    let mockCartInput = MockCartInput()

    var homeEventHandler: ((HomeEvent) -> Void)?

    func makeViewController(for route: MainTabsRoute) -> UIViewController {
        switch route {
        case .home(let eventHandler):
            homeEventHandler = eventHandler
            return homeViewController
        case .cart(let onCreated):
            onCreated(mockCartInput)
            return cartViewController
        }
    }
}

@MainActor
private final class MockCartInput: CartInput {
    private(set) var placeOrderCalls: [Int] = []

    func placeOrder(_ orderID: Int) {
        placeOrderCalls.append(orderID)
    }
}

@MainActor
private final class MockTabRouter: TabRouting {
    var root: RouterRoot { RouterRoot(UIViewController()) }
    func extractRootUI() -> UIViewController { return UIViewController() }

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
