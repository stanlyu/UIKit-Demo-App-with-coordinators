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

    let cartInput = MockCartInput()

    var homeEventHandler: ((HomeEvent) -> Void)?

    func makeHomeViewController(with eventHandler: @escaping (HomeEvent) -> Void) -> UIViewController {
        homeEventHandler = eventHandler
        return homeViewController
    }

    func makeCartViewController() -> CartModule {
        (cartViewController, cartInput)
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
