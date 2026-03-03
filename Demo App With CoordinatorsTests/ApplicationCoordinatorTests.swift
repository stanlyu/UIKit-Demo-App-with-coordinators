import UIKit
import Testing
@testable import Core
@testable import Demo_App_With_Coordinators

@MainActor
struct ApplicationCoordinatorTests {
    @Test
    func start_setsLaunchScreenAsRootWithoutAnimation() {
        let sut = makeSUT()
        
        sut.coordinator.start(with: sut.router)
        
        #expect(sut.router.setRootCalls.count == 1)
        #expect(sut.router.setRootCalls[0].item.viewController === sut.composer.launchViewController)
        #expect(sut.router.setRootCalls[0].animated == false)
    }
    
    @Test
    func launchMainFlowEvent_replacesRootWithMainTabsAnimated() {
        let sut = makeSUT()
        sut.coordinator.start(with: sut.router)
        
        sut.composer.launchEventHandler?(.mainFlowStarted)
        
        #expect(sut.router.setRootCalls.count == 2)
        #expect(sut.router.setRootCalls[1].item.viewController === sut.composer.mainTabsViewController)
        #expect(sut.router.setRootCalls[1].animated == true)
    }
}

@MainActor
private extension ApplicationCoordinatorTests {
    struct SUT {
        let coordinator: ApplicationCoordinatingLogic<MockSwitchRouter>
        let composer: MockApplicationComposer
        let router: MockSwitchRouter
    }
    
    func makeSUT() -> SUT {
        let composer = MockApplicationComposer()
        let router = MockSwitchRouter()
        let coordinator = ApplicationCoordinatingLogic<MockSwitchRouter>(composer: composer)
        return SUT(coordinator: coordinator, composer: composer, router: router)
    }
}

@MainActor
private final class MockApplicationComposer: ApplicationComposing {
    let launchViewController = UIViewController()
    let mainTabsViewController = UIViewController()
    
    var launchEventHandler: ((LaunchScreenEvent) -> Void)?
    
    func makeViewController(for route: ApplicationRoute) -> UIViewController {
        switch route {
        case .launch(let eventHandler):
            launchEventHandler = eventHandler
            return launchViewController
        case .mainFlow:
            return mainTabsViewController
        }
    }
}

@MainActor
private final class MockSwitchRouter: SwitchRouting {
    var root: RouterRoot { RouterRoot(UIViewController()) }
    func extractRootUI() -> UIViewController { return UIViewController() }

    struct SetRootCall {
        let item: RouterItem
        let animated: Bool
    }
    
    private(set) var setRootCalls: [SetRootCall] = []
    
    func setRoot(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        setRootCalls.append(SetRootCall(item: item, animated: animated))
        completion?()
    }
    
    func present(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {}
    func dismiss(animated: Bool, completion: (() -> Void)?) {}
}
