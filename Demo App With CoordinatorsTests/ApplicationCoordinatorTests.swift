import UIKit
import Testing
@testable import Core
@testable import Demo_App_With_Coordinators

@MainActor
struct ApplicationCoordinatorTests {
    @Test
    func start_setsLaunchScreenAsRootWithoutAnimation() {
        let sut = makeSUT()
        
        sut.coordinator.start(CoordinatorStartContext())
        
        #expect(sut.router.switchToCalls.count == 1)
        #expect(sut.router.switchToCalls[0].item.isWrapping(sut.composer.launchViewController))
        #expect(sut.router.switchToCalls[0].animated == false)
    }
    
    @Test
    func launchMainFlowEvent_replacesRootWithMainTabsAnimated() {
        let sut = makeSUT()
        sut.coordinator.start(CoordinatorStartContext())
        
        sut.composer.launchEventHandler?(.mainFlowStarted)
        
        #expect(sut.router.switchToCalls.count == 2)
        #expect(sut.router.switchToCalls[1].item.isWrapping(sut.composer.mainTabsViewController))
        #expect(sut.router.switchToCalls[1].animated == true)
    }
}

@MainActor
private extension ApplicationCoordinatorTests {
    struct SUT {
        let coordinator: ApplicationCoordinatingLogic
        let composer: MockApplicationComposer
        let router: MockSwitchRouter
    }
    
    func makeSUT() -> SUT {
        let composer = MockApplicationComposer()
        let router = MockSwitchRouter()
        let coordinator = ApplicationCoordinatingLogic(router: router, composer: composer)
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
private final class MockSwitchRouter: SwitchNavigation {
    struct SwitchToCall {
        let item: RouterItem
        let animated: Bool
    }
    
    var currentItem: RouterItem?
    private(set) var switchToCalls: [SwitchToCall] = []
    
    func switchTo(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        currentItem = item
        switchToCalls.append(SwitchToCall(item: item, animated: animated))
        completion?()
    }
    
    func present(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {}
    func dismiss(animated: Bool, completion: (() -> Void)?) {}
}
