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
private final class SingleViewControllerComposer: Composing {
    init(viewController: UIViewController) {
        self.viewController = viewController
    }

    func makeViewController(for route: FlowTestRoute) -> UIViewController {
        viewController
    }

    private let viewController: UIViewController
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
private final class StateFlowAttachmentManager: FlowAttachmentManaging {
    func retain(_ retainer: AnyObject, to viewController: UIViewController) {
        let viewControllerID = ObjectIdentifier(viewController)
        var retainedObjects = retainedObjectsByViewController[viewControllerID] ?? [:]
        retainedObjects[ObjectIdentifier(retainer)] = retainer
        retainedObjectsByViewController[viewControllerID] = retainedObjects
    }

    func release(_ retainer: AnyObject, from viewController: UIViewController) {
        let viewControllerID = ObjectIdentifier(viewController)
        retainedObjectsByViewController[viewControllerID]?.removeValue(forKey: ObjectIdentifier(retainer))
    }

    func attach(_ runtime: any FlowRuntimeNode, to viewController: UIViewController) {
        runtimeByViewController[ObjectIdentifier(viewController)] = WeakRuntime(runtime)
        retain(runtime, to: viewController)
    }

    func detach(_ runtime: any FlowRuntimeNode, from viewController: UIViewController) {
        let viewControllerID = ObjectIdentifier(viewController)
        if runtimeByViewController[viewControllerID]?.runtime === runtime {
            runtimeByViewController.removeValue(forKey: viewControllerID)
        }
        release(runtime, from: viewController)
    }

    func runtime(attachedTo viewController: UIViewController) -> (any FlowRuntimeNode)? {
        runtimeByViewController[ObjectIdentifier(viewController)]?.runtime
    }

    private final class WeakRuntime {
        init(_ runtime: any FlowRuntimeNode) {
            self.runtime = runtime
        }

        weak var runtime: (any FlowRuntimeNode)?
    }

    private var retainedObjectsByViewController: [ObjectIdentifier: [ObjectIdentifier: AnyObject]] = [:]
    private var runtimeByViewController: [ObjectIdentifier: WeakRuntime] = [:]
}

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

        #expect(flow.coordinator.router.currentItem?.isWrapping(composer.detailsViewController) == true)
    }

    @Test func parentFlow_adoptsChildFlowReturnedAsViewController() throws {
        let attachmentManager = StateFlowAttachmentManager()
        let childComposer = FlowTestComposer()
        let childFlow = Flow.inline(attachmentManager: attachmentManager, composer: childComposer) { router, composer in
            InlineFlowTestCoordinator(router: router, composer: composer)
        }

        let parentComposer = SingleViewControllerComposer(viewController: childFlow.viewController)
        let parentFlow = Flow.stack(attachmentManager: attachmentManager, composer: parentComposer) { router, composer in
            StackFlowTestCoordinator(router: router, composer: composer)
        }

        let parentRuntime = try #require(attachmentManager.runtime(attachedTo: parentFlow.viewController))
        let childRuntime = try #require(attachmentManager.runtime(attachedTo: childFlow.viewController))

        #expect(parentRuntime.children.contains { $0 === childRuntime })
        #expect(childRuntime.parent === parentRuntime)
    }
}
