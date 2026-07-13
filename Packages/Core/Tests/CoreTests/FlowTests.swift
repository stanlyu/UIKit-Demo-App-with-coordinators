import Testing
import UIKit
@testable import Core

private enum FlowTestRoute {
    case root
    case details
}

private enum RuntimeStackRoute: Hashable {
    case root
    case childA
    case childB
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
private final class RuntimeStackComposer: Composing {
    init(viewControllers: [RuntimeStackRoute: UIViewController]) {
        self.viewControllers = viewControllers
    }

    var rootViewController: UIViewController {
        viewControllers[.root]!
    }

    func makeViewController(for route: RuntimeStackRoute) -> UIViewController {
        viewControllers[route]!
    }

    private let viewControllers: [RuntimeStackRoute: UIViewController]
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
private final class RuntimeStackCoordinator: BaseCoordinator<any StackNavigation, RuntimeStackRoute> {
    override func start(_ context: CoordinatorStartContext) {
        router.setRoot(composer.makeItem(for: .root), animated: false)
    }

    func push(_ route: RuntimeStackRoute) {
        router.push(composer.makeItem(for: route), animated: false)
    }

    func push(_ route: RuntimeStackRoute, completion: @escaping () -> Void) {
        router.push(composer.makeItem(for: route), animated: false, completion: completion)
    }

    func pop() {
        router.pop(animated: false)
    }

    func pop(completion: @escaping () -> Void) {
        router.pop(animated: false, completion: completion)
    }

    func popToRoot() {
        router.popToRoot(animated: false)
    }

    func popTo(_ route: RuntimeStackRoute) {
        router.popTo(composer.makeItem(for: route), animated: false)
    }

    func setStack(_ routes: [RuntimeStackRoute]) {
        router.setStack(routes.map { composer.makeItem(for: $0) }, animated: false)
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
        let viewControllerID = ObjectIdentifier(viewController)
        runtimeLookupCounts[viewControllerID, default: 0] += 1
        return runtimeByViewController[viewControllerID]?.runtime
    }

    func runtimeLookupCount(attachedTo viewController: UIViewController) -> Int {
        runtimeLookupCounts[ObjectIdentifier(viewController)] ?? 0
    }

    private final class WeakRuntime {
        init(_ runtime: any FlowRuntimeNode) {
            self.runtime = runtime
        }

        weak var runtime: (any FlowRuntimeNode)?
    }

    private var retainedObjectsByViewController: [ObjectIdentifier: [ObjectIdentifier: AnyObject]] = [:]
    private var runtimeByViewController: [ObjectIdentifier: WeakRuntime] = [:]
    private var runtimeLookupCounts: [ObjectIdentifier: Int] = [:]
}

@MainActor
private final class CapturingNavigationDelegate: NSObject, UINavigationControllerDelegate {
    private(set) var didShowCallCount = 0
    private(set) var animationControllerCallCount = 0
    private(set) var interactionControllerCallCount = 0
    private(set) var supportedOrientationsCallCount = 0
    private(set) var preferredOrientationCallCount = 0
    var animator: (any UIViewControllerAnimatedTransitioning)?
    var interactionController: (any UIViewControllerInteractiveTransitioning)?
    var supportedOrientations: UIInterfaceOrientationMask = .landscape
    var preferredOrientation: UIInterfaceOrientation = .landscapeLeft

    func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        didShowCallCount += 1
    }

    func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> (any UIViewControllerAnimatedTransitioning)? {
        animationControllerCallCount += 1
        return animator
    }

    func navigationController(
        _ navigationController: UINavigationController,
        interactionControllerFor animationController: any UIViewControllerAnimatedTransitioning
    ) -> (any UIViewControllerInteractiveTransitioning)? {
        interactionControllerCallCount += 1
        return interactionController
    }

    func navigationControllerSupportedInterfaceOrientations(
        _ navigationController: UINavigationController
    ) -> UIInterfaceOrientationMask {
        supportedOrientationsCallCount += 1
        return supportedOrientations
    }

    func navigationControllerPreferredInterfaceOrientationForPresentation(
        _ navigationController: UINavigationController
    ) -> UIInterfaceOrientation {
        preferredOrientationCallCount += 1
        return preferredOrientation
    }
}

private final class SentinelAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
        0
    }

    func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {}
}

private final class SentinelInteractionController: NSObject, UIViewControllerInteractiveTransitioning {
    func startInteractiveTransition(_ transitionContext: any UIViewControllerContextTransitioning) {}
}

@MainActor
private func makeInlineChildFlow(
    attachmentManager: StateFlowAttachmentManager,
    viewController: UIViewController = UIViewController()
) -> CreatedFlow<InlineFlowTestCoordinator> {
    Flow.inline(
        attachmentManager: attachmentManager,
        composer: SingleViewControllerComposer(viewController: viewController)
    ) { router, composer in
        InlineFlowTestCoordinator(router: router, composer: composer)
    }
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

    @Test func stackFlow_pushAdoptsChildRuntime() throws {
        let attachmentManager = StateFlowAttachmentManager()
        let childFlow = makeInlineChildFlow(attachmentManager: attachmentManager)
        let composer = RuntimeStackComposer(viewControllers: [
            .root: UIViewController(),
            .childA: childFlow.viewController
        ])

        let parentFlow = Flow.stack(attachmentManager: attachmentManager, composer: composer) { router, composer in
            RuntimeStackCoordinator(router: router, composer: composer)
        }
        parentFlow.coordinator.push(.childA)

        let parentRuntime = try #require(attachmentManager.runtime(attachedTo: parentFlow.viewController))
        let childRuntime = try #require(attachmentManager.runtime(attachedTo: childFlow.viewController))
        #expect(parentRuntime.children.contains { $0 === childRuntime })
        #expect(childRuntime.parent === parentRuntime)
    }

    @Test func stackFlow_pushAppliesRuntimeMutationBeforeUserCompletion() throws {
        let attachmentManager = StateFlowAttachmentManager()
        let childFlow = makeInlineChildFlow(attachmentManager: attachmentManager)
        let composer = RuntimeStackComposer(viewControllers: [
            .root: UIViewController(),
            .childA: childFlow.viewController
        ])

        let parentFlow = Flow.stack(attachmentManager: attachmentManager, composer: composer) { router, composer in
            RuntimeStackCoordinator(router: router, composer: composer)
        }

        let parentRuntime = try #require(attachmentManager.runtime(attachedTo: parentFlow.viewController))
        let childRuntime = try #require(attachmentManager.runtime(attachedTo: childFlow.viewController))
        var didObserveAppliedMutationInCompletion = false

        parentFlow.coordinator.push(.childA) {
            didObserveAppliedMutationInCompletion = parentRuntime.children.contains { $0 === childRuntime }
                && childRuntime.parent === parentRuntime
        }

        #expect(didObserveAppliedMutationInCompletion)
    }

    @Test func stackFlow_popRemovesChildRuntime() throws {
        let attachmentManager = StateFlowAttachmentManager()
        let childFlow = makeInlineChildFlow(attachmentManager: attachmentManager)
        let composer = RuntimeStackComposer(viewControllers: [
            .root: UIViewController(),
            .childA: childFlow.viewController
        ])

        let parentFlow = Flow.stack(attachmentManager: attachmentManager, composer: composer) { router, composer in
            RuntimeStackCoordinator(router: router, composer: composer)
        }
        parentFlow.coordinator.push(.childA)

        let parentRuntime = try #require(attachmentManager.runtime(attachedTo: parentFlow.viewController))
        let childRuntime = try #require(attachmentManager.runtime(attachedTo: childFlow.viewController))

        parentFlow.coordinator.pop()

        #expect(!parentRuntime.children.contains { $0 === childRuntime })
        #expect(childRuntime.parent == nil)
    }

    @Test func stackFlow_popAppliesRuntimeMutationBeforeUserCompletion() throws {
        let attachmentManager = StateFlowAttachmentManager()
        let childFlow = makeInlineChildFlow(attachmentManager: attachmentManager)
        let composer = RuntimeStackComposer(viewControllers: [
            .root: UIViewController(),
            .childA: childFlow.viewController
        ])

        let parentFlow = Flow.stack(attachmentManager: attachmentManager, composer: composer) { router, composer in
            RuntimeStackCoordinator(router: router, composer: composer)
        }
        parentFlow.coordinator.push(.childA)

        let parentRuntime = try #require(attachmentManager.runtime(attachedTo: parentFlow.viewController))
        let childRuntime = try #require(attachmentManager.runtime(attachedTo: childFlow.viewController))
        var didObserveAppliedMutationInCompletion = false

        parentFlow.coordinator.pop {
            didObserveAppliedMutationInCompletion = !parentRuntime.children.contains { $0 === childRuntime }
                && childRuntime.parent == nil
        }

        #expect(didObserveAppliedMutationInCompletion)
    }

    @Test func stackFlow_popToRootRemovesMultipleChildRuntimes() throws {
        let attachmentManager = StateFlowAttachmentManager()
        let childAFlow = makeInlineChildFlow(attachmentManager: attachmentManager)
        let childBFlow = makeInlineChildFlow(attachmentManager: attachmentManager)
        let composer = RuntimeStackComposer(viewControllers: [
            .root: UIViewController(),
            .childA: childAFlow.viewController,
            .childB: childBFlow.viewController
        ])

        let parentFlow = Flow.stack(attachmentManager: attachmentManager, composer: composer) { router, composer in
            RuntimeStackCoordinator(router: router, composer: composer)
        }
        parentFlow.coordinator.push(.childA)
        parentFlow.coordinator.push(.childB)

        let parentRuntime = try #require(attachmentManager.runtime(attachedTo: parentFlow.viewController))
        let childARuntime = try #require(attachmentManager.runtime(attachedTo: childAFlow.viewController))
        let childBRuntime = try #require(attachmentManager.runtime(attachedTo: childBFlow.viewController))

        parentFlow.coordinator.popToRoot()

        #expect(parentRuntime.children.isEmpty)
        #expect(childARuntime.parent == nil)
        #expect(childBRuntime.parent == nil)
    }

    @Test func stackFlow_popToRemovesLaterChildRuntimeAndKeepsTargetRuntime() throws {
        let attachmentManager = StateFlowAttachmentManager()
        let childAFlow = makeInlineChildFlow(attachmentManager: attachmentManager)
        let childBFlow = makeInlineChildFlow(attachmentManager: attachmentManager)
        let composer = RuntimeStackComposer(viewControllers: [
            .root: UIViewController(),
            .childA: childAFlow.viewController,
            .childB: childBFlow.viewController
        ])

        let parentFlow = Flow.stack(attachmentManager: attachmentManager, composer: composer) { router, composer in
            RuntimeStackCoordinator(router: router, composer: composer)
        }
        parentFlow.coordinator.push(.childA)
        parentFlow.coordinator.push(.childB)

        let parentRuntime = try #require(attachmentManager.runtime(attachedTo: parentFlow.viewController))
        let childARuntime = try #require(attachmentManager.runtime(attachedTo: childAFlow.viewController))
        let childBRuntime = try #require(attachmentManager.runtime(attachedTo: childBFlow.viewController))

        parentFlow.coordinator.popTo(.childA)

        #expect(parentRuntime.children.contains { $0 === childARuntime })
        #expect(!parentRuntime.children.contains { $0 === childBRuntime })
        #expect(childARuntime.parent === parentRuntime)
        #expect(childBRuntime.parent == nil)
    }

    @Test func stackFlow_setStackSynchronizesAdditionsAndRemovals() throws {
        let attachmentManager = StateFlowAttachmentManager()
        let childAFlow = makeInlineChildFlow(attachmentManager: attachmentManager)
        let childBFlow = makeInlineChildFlow(attachmentManager: attachmentManager)
        let composer = RuntimeStackComposer(viewControllers: [
            .root: UIViewController(),
            .childA: childAFlow.viewController,
            .childB: childBFlow.viewController
        ])

        let parentFlow = Flow.stack(attachmentManager: attachmentManager, composer: composer) { router, composer in
            RuntimeStackCoordinator(router: router, composer: composer)
        }
        parentFlow.coordinator.push(.childA)

        let parentRuntime = try #require(attachmentManager.runtime(attachedTo: parentFlow.viewController))
        let childARuntime = try #require(attachmentManager.runtime(attachedTo: childAFlow.viewController))
        let childBRuntime = try #require(attachmentManager.runtime(attachedTo: childBFlow.viewController))

        parentFlow.coordinator.setStack([.root, .childB])

        #expect(!parentRuntime.children.contains { $0 === childARuntime })
        #expect(parentRuntime.children.contains { $0 === childBRuntime })
        #expect(childARuntime.parent == nil)
        #expect(childBRuntime.parent === parentRuntime)
    }

    @Test func stackFlow_nativeBackDelegatePopRemovesChildRuntime() throws {
        let attachmentManager = StateFlowAttachmentManager()
        let childFlow = makeInlineChildFlow(attachmentManager: attachmentManager)
        let composer = RuntimeStackComposer(viewControllers: [
            .root: UIViewController(),
            .childA: childFlow.viewController
        ])

        let parentFlow = Flow.stack(attachmentManager: attachmentManager, composer: composer) { router, composer in
            RuntimeStackCoordinator(router: router, composer: composer)
        }
        parentFlow.coordinator.push(.childA)

        let navigationController = try #require(parentFlow.viewController as? UINavigationController)
        let dispatcher = try #require(navigationController.delegate as? NavigationControllerDelegateDispatcher)
        let parentRuntime = try #require(attachmentManager.runtime(attachedTo: parentFlow.viewController))
        let childRuntime = try #require(attachmentManager.runtime(attachedTo: childFlow.viewController))

        navigationController.setViewControllers([composer.rootViewController], animated: false)
        dispatcher.navigationController(navigationController, didShow: composer.rootViewController, animated: false)

        #expect(!parentRuntime.children.contains { $0 === childRuntime })
        #expect(childRuntime.parent == nil)
    }

    @Test func stackFlow_externalDeltaDoesNotCreateInsertedItems() {
        let rootViewController = UIViewController()
        let removedViewController = UIViewController()
        let retainedViewController = UIViewController()
        let externallyInsertedViewController = UIViewController()

        let mutation = NavigationMutation.externalStackDelta(
            oldStack: [rootViewController, removedViewController, retainedViewController],
            newStack: [rootViewController, retainedViewController, externallyInsertedViewController]
        )

        #expect(mutation.insertedItems.isEmpty)
        #expect(mutation.removedViewControllers == [removedViewController])
    }

    @Test func stackFlow_programmaticPopIsNotProcessedTwiceThroughDelegateCallback() throws {
        let attachmentManager = StateFlowAttachmentManager()
        let childFlow = makeInlineChildFlow(attachmentManager: attachmentManager)
        let composer = RuntimeStackComposer(viewControllers: [
            .root: UIViewController(),
            .childA: childFlow.viewController
        ])

        let parentFlow = Flow.stack(attachmentManager: attachmentManager, composer: composer) { router, composer in
            RuntimeStackCoordinator(router: router, composer: composer)
        }
        parentFlow.coordinator.push(.childA)

        let navigationController = try #require(parentFlow.viewController as? UINavigationController)
        let dispatcher = try #require(navigationController.delegate as? NavigationControllerDelegateDispatcher)
        let lookupCountBeforePop = attachmentManager.runtimeLookupCount(attachedTo: childFlow.viewController)

        parentFlow.coordinator.pop()
        let lookupCountAfterPop = attachmentManager.runtimeLookupCount(attachedTo: childFlow.viewController)
        dispatcher.navigationController(navigationController, didShow: composer.rootViewController, animated: false)

        #expect(lookupCountAfterPop == lookupCountBeforePop + 1)
        #expect(attachmentManager.runtimeLookupCount(attachedTo: childFlow.viewController) == lookupCountAfterPop)
    }

    @Test func stackFlow_delegateProxyKeepsExistingExternalDelegate() throws {
        let attachmentManager = StateFlowAttachmentManager()
        let externalDelegate = CapturingNavigationDelegate()
        let navigationController = UINavigationController()
        navigationController.delegate = externalDelegate
        let composer = RuntimeStackComposer(viewControllers: [
            .root: UIViewController()
        ])

        let flow = Flow.stack(
            attachmentManager: attachmentManager,
            makeNavigationController: { navigationController },
            composer: composer
        ) { router, composer in
            RuntimeStackCoordinator(router: router, composer: composer)
        }

        let dispatcher = try #require(navigationController.delegate as? NavigationControllerDelegateDispatcher)
        dispatcher.navigationController(navigationController, didShow: composer.rootViewController, animated: false)

        #expect(flow.viewController === navigationController)
        #expect(externalDelegate.didShowCallCount == 1)
    }

    @Test func stackFlow_delegateProxyReturnsExternalDelegateTransitionCallbacks() throws {
        let attachmentManager = StateFlowAttachmentManager()
        let externalDelegate = CapturingNavigationDelegate()
        let animator = SentinelAnimator()
        let interactionController = SentinelInteractionController()
        externalDelegate.animator = animator
        externalDelegate.interactionController = interactionController
        let navigationController = UINavigationController()
        navigationController.delegate = externalDelegate
        let composer = RuntimeStackComposer(viewControllers: [
            .root: UIViewController()
        ])

        _ = Flow.stack(
            attachmentManager: attachmentManager,
            makeNavigationController: { navigationController },
            composer: composer
        ) { router, composer in
            RuntimeStackCoordinator(router: router, composer: composer)
        }

        let dispatcher = try #require(navigationController.delegate as? NavigationControllerDelegateDispatcher)
        let fromViewController = UIViewController()
        let toViewController = UIViewController()
        let returnedAnimator = try #require(dispatcher.navigationController(
            navigationController,
            animationControllerFor: .push,
            from: fromViewController,
            to: toViewController
        ))
        let returnedInteractionController = try #require(dispatcher.navigationController(
            navigationController,
            interactionControllerFor: animator
        ))

        #expect(returnedAnimator as AnyObject === animator)
        #expect(returnedInteractionController as AnyObject === interactionController)
        #expect(externalDelegate.animationControllerCallCount == 1)
        #expect(externalDelegate.interactionControllerCallCount == 1)
    }

    @Test func stackFlow_delegateProxyKeepsExistingExternalDelegateOrientationCallbacks() throws {
        let attachmentManager = StateFlowAttachmentManager()
        let externalDelegate = CapturingNavigationDelegate()
        externalDelegate.supportedOrientations = .portrait
        externalDelegate.preferredOrientation = .portraitUpsideDown
        let navigationController = UINavigationController()
        navigationController.delegate = externalDelegate
        let composer = RuntimeStackComposer(viewControllers: [
            .root: UIViewController()
        ])

        _ = Flow.stack(
            attachmentManager: attachmentManager,
            makeNavigationController: { navigationController },
            composer: composer
        ) { router, composer in
            RuntimeStackCoordinator(router: router, composer: composer)
        }

        let dispatcher = try #require(navigationController.delegate as? NavigationControllerDelegateDispatcher)
        let supportedOrientations = dispatcher.navigationControllerSupportedInterfaceOrientations(navigationController)
        let preferredOrientation = dispatcher.navigationControllerPreferredInterfaceOrientationForPresentation(
            navigationController
        )

        #expect(supportedOrientations == .portrait)
        #expect(preferredOrientation == .portraitUpsideDown)
        #expect(externalDelegate.supportedOrientationsCallCount == 1)
        #expect(externalDelegate.preferredOrientationCallCount == 1)
    }
}
