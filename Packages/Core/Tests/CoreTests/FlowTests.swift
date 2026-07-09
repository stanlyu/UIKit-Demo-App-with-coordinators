import Testing
import UIKit
@testable import Core

private enum FlowTestRoute {
    case root
    case details
}

@MainActor
private final class FlowTestComposer: Composing {
    let rootViewController = UIViewController()
    let detailsViewController = UIViewController()

    func makeViewController(for route: FlowTestRoute) -> UIViewController {
        switch route {
        case .root:
            return rootViewController
        case .details:
            return detailsViewController
        }
    }
}

@MainActor
private protocol FlowTestNavigationInput: AnyObject {
    func openDetails()
}

@MainActor
private final class StackFlowTestCoordinator:
    BaseCoordinator<any StackNavigation, FlowTestRoute>,
    FlowTestNavigationInput
{
    private(set) var startCallCount = 0

    override func start(_ context: CoordinatorStartContext) {
        startCallCount += 1
        router.setRoot(composer.makeItem(for: .root), animated: false)
    }

    func openDetails() {
        router.push(composer.makeItem(for: .details), animated: false)
    }
}

@MainActor
private final class InlineFlowTestCoordinator: BaseCoordinator<any StackNavigation, FlowTestRoute> {
    override func start(_ context: CoordinatorStartContext) {
        router.setRoot(composer.makeItem(for: .root), animated: false)
    }
}

@MainActor
private final class SwitchFlowTestCoordinator: BaseCoordinator<any SwitchNavigation, FlowTestRoute> {
    override func start(_ context: CoordinatorStartContext) {
        router.switchTo(composer.makeItem(for: .root), animated: false)
    }

    func switchToDetails() {
        router.switchTo(composer.makeItem(for: .details), animated: false)
    }
}

@MainActor
private final class CustomNavigationController: UINavigationController {}

@MainActor
@Suite("Flow API")
struct FlowTests {
    @Test func stackFlow_startsCoordinatorAndReturnsNavigationController() throws {
        let composer = FlowTestComposer()

        let flow = Flow.stack(composer: composer) { router, composer in
            StackFlowTestCoordinator(router: router, composer: composer)
        }

        let navigationController = try #require(flow.viewController as? UINavigationController)
        #expect(flow.coordinator.startCallCount == 1)
        #expect(navigationController.viewControllers.first === composer.rootViewController)
    }

    @Test func stackFlow_supportsCustomNavigationController() throws {
        let composer = FlowTestComposer()

        let flow = Flow.stack(
            makeNavigationController: {
                let navigationController = CustomNavigationController()
                navigationController.isNavigationBarHidden = true
                return navigationController
            },
            composer: composer
        ) { router, composer in
            StackFlowTestCoordinator(router: router, composer: composer)
        }

        let navigationController = try #require(flow.viewController as? CustomNavigationController)
        #expect(navigationController.isNavigationBarHidden)
    }

    @Test func stackFlow_returnsCoordinatorForNavigationInput() throws {
        let composer = FlowTestComposer()

        let flow = Flow.stack(composer: composer) { router, composer in
            StackFlowTestCoordinator(router: router, composer: composer)
        }
        let input: any FlowTestNavigationInput = flow.coordinator
        input.openDetails()

        let navigationController = try #require(flow.viewController as? UINavigationController)
        #expect(navigationController.viewControllers.last === composer.detailsViewController)
    }

    @Test func inlineFlow_returnsInitialContentController() {
        let composer = FlowTestComposer()

        let flow = Flow.inline(composer: composer) { router, composer in
            InlineFlowTestCoordinator(router: router, composer: composer)
        }

        #expect(flow.viewController === composer.rootViewController)
    }

    @Test func switchingFlow_returnsInitialContentAndCanSwitchContent() {
        let composer = FlowTestComposer()

        let flow = Flow.switching(composer: composer) { router, composer in
            SwitchFlowTestCoordinator(router: router, composer: composer)
        }

        #expect(flow.viewController === composer.rootViewController)

        flow.coordinator.switchToDetails()

        #expect(flow.coordinator.router.currentItem?.viewController === composer.detailsViewController)
    }
}
