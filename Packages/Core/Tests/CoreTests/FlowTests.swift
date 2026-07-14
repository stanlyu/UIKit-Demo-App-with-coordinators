import Testing
import UIKit
@testable import Core

private enum FlowTestRoute {
    case root
    case details
}

private enum InstanceStackRoute: Hashable {
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
private final class InstanceStackComposer: Composing {
    init(viewControllers: [InstanceStackRoute: UIViewController]) {
        self.viewControllers = viewControllers
    }

    var rootViewController: UIViewController {
        viewControllers[.root]!
    }

    func makeViewController(for route: InstanceStackRoute) -> UIViewController {
        viewControllers[route]!
    }

    private let viewControllers: [InstanceStackRoute: UIViewController]
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
private final class TransientViewControllerComposer: Composing {
    func makeViewController(for route: FlowTestRoute) -> UIViewController {
        UIViewController()
    }
}

@MainActor
private final class EphemeralChildFlowComposer: Composing {
    let rootViewController = UIViewController()
    weak var childAViewController: UIViewController?
    weak var childAInstance: (any FlowInstanceNode)?
    weak var childBViewController: UIViewController?
    weak var childBInstance: (any FlowInstanceNode)?

    func makeViewController(for route: InstanceStackRoute) -> UIViewController {
        switch route {
        case .root:
            return rootViewController
        case .childA:
            return makeChildFlow(
                updateViewController: { childAViewController = $0 },
                updateInstance: { childAInstance = $0 }
            )
        case .childB:
            return makeChildFlow(
                updateViewController: { childBViewController = $0 },
                updateInstance: { childBInstance = $0 }
            )
        }
    }

    private func makeChildFlow(
        updateViewController: (UIViewController) -> Void,
        updateInstance: ((any FlowInstanceNode)?) -> Void
    ) -> UIViewController {
        let flow = Flow.inline(
            composer: TransientViewControllerComposer()
        ) { router, composer in
            InlineFlowTestCoordinator(router: router, composer: composer)
        }
        updateViewController(flow.viewController)
        updateInstance(FlowInstanceAttachments.default.instance(attachedTo: flow.viewController))
        return flow.viewController
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
private final class InstanceStackCoordinator: BaseCoordinator<any StackNavigation, InstanceStackRoute> {
    override func start(_ context: CoordinatorStartContext) {
        router.setRoot(composer.makeItem(for: .root), animated: false)
    }

    func push(_ route: InstanceStackRoute) {
        router.push(composer.makeItem(for: route), animated: false)
    }

    func push(_ route: InstanceStackRoute, completion: @escaping () -> Void) {
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

    func popTo(_ route: InstanceStackRoute) {
        router.popTo(composer.makeItem(for: route), animated: false)
    }

    func setStack(_ routes: [InstanceStackRoute]) {
        router.setStack(routes.map { composer.makeItem(for: $0) }, animated: false)
    }

    func pushThroughContext(_ route: InstanceStackRoute, context: any NavigationStackContext) {
        context.push(composer.makeItem(for: route), animated: false)
    }
}

@MainActor
private final class InstanceTabCoordinator: BaseCoordinator<any TabNavigation, InstanceStackRoute> {
    override func start(_ context: CoordinatorStartContext) {
        router.setItems(
            [
                composer.makeItem(for: .root),
                composer.makeItem(for: .childA)
            ],
            animated: false
        )
    }

    func replaceTabs(_ routes: [InstanceStackRoute]) {
        router.setItems(routes.map { composer.makeItem(for: $0) }, animated: false)
    }
}

@MainActor
private final class InstanceSwitchCoordinator: BaseCoordinator<any SwitchNavigation, InstanceStackRoute> {
    override func start(_ context: CoordinatorStartContext) {
        router.switchTo(composer.makeItem(for: .root), animated: false)
    }

    func switchTo(_ route: InstanceStackRoute) {
        router.switchTo(composer.makeItem(for: route), animated: false)
    }

    func switchTo(_ route: InstanceStackRoute, animated: Bool, completion: @escaping () -> Void) {
        router.switchTo(composer.makeItem(for: route), animated: animated, completion: completion)
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
private final class ControlledPresentationNavigationController: UINavigationController {
    override var presentedViewController: UIViewController? {
        controlledPresentedViewController
    }

    override func present(
        _ viewControllerToPresent: UIViewController,
        animated flag: Bool,
        completion: (() -> Void)? = nil
    ) {
        controlledPresentedViewController = viewControllerToPresent
        completion?()
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        pendingDismissCompletion = completion
    }

    func completeDismiss() {
        controlledPresentedViewController = nil
        let completion = pendingDismissCompletion
        pendingDismissCompletion = nil
        completion?()
    }

    private var controlledPresentedViewController: UIViewController?
    private var pendingDismissCompletion: (() -> Void)?
}

@MainActor
private final class StateFlowInstanceAttachments: FlowInstanceAttachmentStoring {
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

    func attach(_ instance: any FlowInstanceNode, to viewController: UIViewController) {
        let viewControllerID = ObjectIdentifier(viewController)
        let instanceID = ObjectIdentifier(instance)
        if instanceByViewController[viewControllerID] == nil {
            instanceByViewController[viewControllerID] = [:]
            instanceOrderByViewController[viewControllerID] = []
        }
        if instanceByViewController[viewControllerID]?[instanceID] == nil {
            instanceOrderByViewController[viewControllerID]?.append(instanceID)
        }
        instanceByViewController[viewControllerID]?[instanceID] = WeakInstance(instance)
        retain(instance, to: viewController)
    }

    func detach(_ instance: any FlowInstanceNode, from viewController: UIViewController) {
        let viewControllerID = ObjectIdentifier(viewController)
        let instanceID = ObjectIdentifier(instance)
        instanceByViewController[viewControllerID]?.removeValue(forKey: instanceID)
        instanceOrderByViewController[viewControllerID]?.removeAll { $0 == instanceID }
        release(instance, from: viewController)
    }

    func instance(attachedTo viewController: UIViewController) -> (any FlowInstanceNode)? {
        let viewControllerID = ObjectIdentifier(viewController)
        instanceLookupCounts[viewControllerID, default: 0] += 1
        return instances(attachedTo: viewController).first
    }

    func instances(attachedTo viewController: UIViewController) -> [any FlowInstanceNode] {
        let viewControllerID = ObjectIdentifier(viewController)
        instancesLookupCounts[viewControllerID, default: 0] += 1
        instanceOrderByViewController[viewControllerID]?.removeAll {
            instanceByViewController[viewControllerID]?[$0]?.instance == nil
        }
        return instanceOrderByViewController[viewControllerID]?
            .compactMap { instanceByViewController[viewControllerID]?[$0]?.instance }
            ?? []
    }

    func instanceLookupCount(attachedTo viewController: UIViewController) -> Int {
        instanceLookupCounts[ObjectIdentifier(viewController)] ?? 0
    }

    func instancesLookupCount(attachedTo viewController: UIViewController) -> Int {
        instancesLookupCounts[ObjectIdentifier(viewController)] ?? 0
    }

    private final class WeakInstance {
        init(_ instance: any FlowInstanceNode) {
            self.instance = instance
        }

        weak var instance: (any FlowInstanceNode)?
    }

    private var retainedObjectsByViewController: [ObjectIdentifier: [ObjectIdentifier: AnyObject]] = [:]
    private var instanceByViewController: [ObjectIdentifier: [ObjectIdentifier: WeakInstance]] = [:]
    private var instanceOrderByViewController: [ObjectIdentifier: [ObjectIdentifier]] = [:]
    private var instanceLookupCounts: [ObjectIdentifier: Int] = [:]
    private var instancesLookupCounts: [ObjectIdentifier: Int] = [:]
}

@MainActor
private final class SpyFlowInstanceNode: FlowInstanceNode {
    var parent: (any FlowInstanceNode)?
    private(set) var children: [any FlowInstanceNode] = []

    func adopt(_ child: any FlowInstanceNode) {
        children.append(child)
        child.setParent(self)
    }

    func removeChild(_ child: any FlowInstanceNode) {
        children.removeAll { $0 === child }
        if child.parent === self {
            child.setParent(nil)
        }
    }

    func setParent(_ parent: (any FlowInstanceNode)?) {
        self.parent = parent
    }
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
    var onDidShow: ((UINavigationController, UIViewController, Bool) -> Void)?

    func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        didShowCallCount += 1
        onDidShow?(navigationController, viewController, animated)
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

private final class WeakObjectBox {
    init(_ object: AnyObject?) {
        self.object = object
    }

    weak var object: AnyObject?
}

private struct FlowLifetimeBoxes {
    let instance: WeakObjectBox
    let router: WeakObjectBox
    let coordinator: WeakObjectBox
}

@MainActor
private func makeInlineChildFlow(
    attachmentManager: StateFlowInstanceAttachments,
    viewController: UIViewController = UIViewController()
) -> CreatedFlow<InlineFlowTestCoordinator> {
    Flow.inline(
        attachmentManager: attachmentManager,
        composer: SingleViewControllerComposer(viewController: viewController)
    ) { router, composer in
        InlineFlowTestCoordinator(router: router, composer: composer)
    }
}

private func object(named name: String, in object: AnyObject) -> AnyObject? {
    Mirror(reflecting: object).children.first { $0.label == name }?.value as AnyObject?
}

@MainActor
private func makeLifetimeBoxes(from instance: (any FlowInstanceNode)?) throws -> FlowLifetimeBoxes {
    let instance = try #require(instance)
    return FlowLifetimeBoxes(
        instance: WeakObjectBox(instance as AnyObject),
        router: WeakObjectBox(object(named: "router", in: instance)),
        coordinator: WeakObjectBox(object(named: "coordinator", in: instance))
    )
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
        let attachmentManager = StateFlowInstanceAttachments()
        let childComposer = FlowTestComposer()
        let childFlow = Flow.inline(attachmentManager: attachmentManager, composer: childComposer) { router, composer in
            InlineFlowTestCoordinator(router: router, composer: composer)
        }

        let parentComposer = SingleViewControllerComposer(viewController: childFlow.viewController)
        let parentFlow = Flow.stack(attachmentManager: attachmentManager, composer: parentComposer) { router, composer in
            StackFlowTestCoordinator(router: router, composer: composer)
        }

        let parentInstance = try #require(attachmentManager.instance(attachedTo: parentFlow.viewController))
        let childInstance = try #require(attachmentManager.instance(attachedTo: childFlow.viewController))

        #expect(parentInstance.children.contains { $0 === childInstance })
        #expect(childInstance.parent === parentInstance)
    }

    @Test func flowRouter_viewControllerResolutionDoesNotAdoptChildInstance() throws {
        let attachmentManager = StateFlowInstanceAttachments()
        let router = FlowRouter<UIViewController, InlineNavigationDriver>(attachmentManager: attachmentManager)
        let parentInstance = SpyFlowInstanceNode()
        let childInstance = SpyFlowInstanceNode()
        let childViewController = UIViewController()
        let item = RouterItem(childViewController, instance: childInstance)
        router.setInstance(parentInstance)

        let resolvedViewController = item.viewController

        #expect(resolvedViewController === childViewController)
        #expect(parentInstance.children.isEmpty)
        #expect(childInstance.parent == nil)

        router.applyInstanceMutation(NavigationMutation(insertedItems: [item]))

        #expect(parentInstance.children.contains { $0 === childInstance })
        #expect(childInstance.parent === parentInstance)
    }

    @Test func associatedObjectAttachmentStoreFallsBackToNextInstanceAfterDetach() throws {
        let attachmentStore = AssociatedObjectFlowInstanceAttachmentStore()
        let viewController = UIViewController()
        let childInstance = SpyFlowInstanceNode()
        let parentInstance = SpyFlowInstanceNode()

        attachmentStore.attach(childInstance, to: viewController)
        attachmentStore.attach(parentInstance, to: viewController)

        #expect(attachmentStore.instance(attachedTo: viewController) === childInstance)

        attachmentStore.detach(childInstance, from: viewController)

        #expect(attachmentStore.instance(attachedTo: viewController) === parentInstance)
    }

    @Test func flowRouter_removalDetachesOnlyDirectChildInstanceOnSharedViewController() throws {
        let attachmentManager = StateFlowInstanceAttachments()
        let router = FlowRouter<UIViewController, InlineNavigationDriver>(attachmentManager: attachmentManager)
        let sharedViewController = UIViewController()
        let grandparentInstance = SpyFlowInstanceNode()
        let parentInstance = SpyFlowInstanceNode()
        let nestedInstance = SpyFlowInstanceNode()
        router.setInstance(grandparentInstance)
        grandparentInstance.adopt(parentInstance)
        parentInstance.adopt(nestedInstance)

        attachmentManager.attach(nestedInstance, to: sharedViewController)
        attachmentManager.attach(parentInstance, to: sharedViewController)

        #expect(attachmentManager.instance(attachedTo: sharedViewController) === nestedInstance)
        #expect(attachmentManager.instances(attachedTo: sharedViewController).contains { $0 === parentInstance })

        router.applyInstanceMutation(NavigationMutation(removedViewControllers: [sharedViewController]))

        #expect(!grandparentInstance.children.contains { $0 === parentInstance })
        #expect(parentInstance.parent == nil)
        #expect(parentInstance.children.contains { $0 === nestedInstance })
        #expect(nestedInstance.parent === parentInstance)
        #expect(!attachmentManager.instances(attachedTo: sharedViewController).contains { $0 === parentInstance })
        #expect(attachmentManager.instances(attachedTo: sharedViewController).contains { $0 === nestedInstance })
    }

    @Test func stackFlow_pushAdoptsChildInstance() throws {
        let attachmentManager = StateFlowInstanceAttachments()
        let childFlow = makeInlineChildFlow(attachmentManager: attachmentManager)
        let composer = InstanceStackComposer(viewControllers: [
            .root: UIViewController(),
            .childA: childFlow.viewController
        ])

        let parentFlow = Flow.stack(attachmentManager: attachmentManager, composer: composer) { router, composer in
            InstanceStackCoordinator(router: router, composer: composer)
        }
        parentFlow.coordinator.push(.childA)

        let parentInstance = try #require(attachmentManager.instance(attachedTo: parentFlow.viewController))
        let childInstance = try #require(attachmentManager.instance(attachedTo: childFlow.viewController))
        #expect(parentInstance.children.contains { $0 === childInstance })
        #expect(childInstance.parent === parentInstance)
    }

    @Test func navigationStackContext_pushItemAdoptsAttachedChildInstance() throws {
        let childFlow = Flow.inline(
            composer: SingleViewControllerComposer(viewController: UIViewController())
        ) { router, composer in
            InlineFlowTestCoordinator(router: router, composer: composer)
        }
        let parentComposer = InstanceStackComposer(viewControllers: [
            .root: UIViewController(),
            .childA: childFlow.viewController
        ])
        let parentFlow = Flow.stack(composer: parentComposer) { router, composer in
            InstanceStackCoordinator(router: router, composer: composer)
        }
        let context: any NavigationStackContext = RouterNavigationStackContext(router: parentFlow.coordinator.router)

        parentFlow.coordinator.pushThroughContext(.childA, context: context)

        let parentInstance = try #require(FlowInstanceAttachments.default.instance(attachedTo: parentFlow.viewController))
        let childInstance = try #require(FlowInstanceAttachments.default.instance(attachedTo: childFlow.viewController))
        #expect(parentInstance.children.contains { $0 === childInstance })
        #expect(childInstance.parent === parentInstance)
    }

    @Test func stackFlow_pushAppliesInstanceMutationBeforeUserCompletion() throws {
        let attachmentManager = StateFlowInstanceAttachments()
        let childFlow = makeInlineChildFlow(attachmentManager: attachmentManager)
        let composer = InstanceStackComposer(viewControllers: [
            .root: UIViewController(),
            .childA: childFlow.viewController
        ])

        let parentFlow = Flow.stack(attachmentManager: attachmentManager, composer: composer) { router, composer in
            InstanceStackCoordinator(router: router, composer: composer)
        }

        let parentInstance = try #require(attachmentManager.instance(attachedTo: parentFlow.viewController))
        let childInstance = try #require(attachmentManager.instance(attachedTo: childFlow.viewController))
        var didObserveAppliedMutationInCompletion = false

        parentFlow.coordinator.push(.childA) {
            didObserveAppliedMutationInCompletion = parentInstance.children.contains { $0 === childInstance }
                && childInstance.parent === parentInstance
        }

        #expect(didObserveAppliedMutationInCompletion)
    }

    @Test func stackFlow_dismissRemovesPresentedChildInstanceInCompletion() throws {
        let attachmentManager = StateFlowInstanceAttachments()
        let navigationController = ControlledPresentationNavigationController()
        let childFlow = makeInlineChildFlow(attachmentManager: attachmentManager)
        let composer = InstanceStackComposer(viewControllers: [
            .root: UIViewController()
        ])
        let parentFlow = Flow.stack(
            attachmentManager: attachmentManager,
            makeNavigationController: { navigationController },
            composer: composer
        ) { router, composer in
            InstanceStackCoordinator(router: router, composer: composer)
        }
        let childItem = RouterItem(
            childFlow.viewController,
            instance: attachmentManager.instance(attachedTo: childFlow.viewController)
        )

        parentFlow.coordinator.router.present(childItem, animated: false, completion: nil)

        let parentInstance = try #require(attachmentManager.instance(attachedTo: parentFlow.viewController))
        let childInstance = try #require(attachmentManager.instance(attachedTo: childFlow.viewController))
        var didObserveCleanupInUserCompletion = false
        #expect(parentInstance.children.contains { $0 === childInstance })
        #expect(childInstance.parent === parentInstance)

        parentFlow.coordinator.router.dismiss(animated: true) {
            didObserveCleanupInUserCompletion = !parentInstance.children.contains { $0 === childInstance }
                && childInstance.parent == nil
                && attachmentManager.instance(attachedTo: childFlow.viewController) == nil
        }

        #expect(parentInstance.children.contains { $0 === childInstance })
        #expect(childInstance.parent === parentInstance)
        #expect(attachmentManager.instance(attachedTo: childFlow.viewController) === childInstance)
        #expect(!didObserveCleanupInUserCompletion)

        navigationController.completeDismiss()

        #expect(didObserveCleanupInUserCompletion)
    }

    @Test func stackFlow_popRemovesChildInstance() throws {
        let attachmentManager = StateFlowInstanceAttachments()
        let childFlow = makeInlineChildFlow(attachmentManager: attachmentManager)
        let composer = InstanceStackComposer(viewControllers: [
            .root: UIViewController(),
            .childA: childFlow.viewController
        ])

        let parentFlow = Flow.stack(attachmentManager: attachmentManager, composer: composer) { router, composer in
            InstanceStackCoordinator(router: router, composer: composer)
        }
        parentFlow.coordinator.push(.childA)

        let parentInstance = try #require(attachmentManager.instance(attachedTo: parentFlow.viewController))
        let childInstance = try #require(attachmentManager.instance(attachedTo: childFlow.viewController))

        parentFlow.coordinator.pop()

        #expect(!parentInstance.children.contains { $0 === childInstance })
        #expect(childInstance.parent == nil)
    }

    @Test func stackFlow_popAppliesInstanceMutationBeforeUserCompletion() throws {
        let attachmentManager = StateFlowInstanceAttachments()
        let childFlow = makeInlineChildFlow(attachmentManager: attachmentManager)
        let composer = InstanceStackComposer(viewControllers: [
            .root: UIViewController(),
            .childA: childFlow.viewController
        ])

        let parentFlow = Flow.stack(attachmentManager: attachmentManager, composer: composer) { router, composer in
            InstanceStackCoordinator(router: router, composer: composer)
        }
        parentFlow.coordinator.push(.childA)

        let parentInstance = try #require(attachmentManager.instance(attachedTo: parentFlow.viewController))
        let childInstance = try #require(attachmentManager.instance(attachedTo: childFlow.viewController))
        var didObserveAppliedMutationInCompletion = false

        parentFlow.coordinator.pop {
            didObserveAppliedMutationInCompletion = !parentInstance.children.contains { $0 === childInstance }
                && childInstance.parent == nil
        }

        #expect(didObserveAppliedMutationInCompletion)
    }

    @Test func stackFlow_popToRootRemovesMultipleChildInstances() throws {
        let attachmentManager = StateFlowInstanceAttachments()
        let childAFlow = makeInlineChildFlow(attachmentManager: attachmentManager)
        let childBFlow = makeInlineChildFlow(attachmentManager: attachmentManager)
        let composer = InstanceStackComposer(viewControllers: [
            .root: UIViewController(),
            .childA: childAFlow.viewController,
            .childB: childBFlow.viewController
        ])

        let parentFlow = Flow.stack(attachmentManager: attachmentManager, composer: composer) { router, composer in
            InstanceStackCoordinator(router: router, composer: composer)
        }
        parentFlow.coordinator.push(.childA)
        parentFlow.coordinator.push(.childB)

        let childAInstance = try #require(attachmentManager.instance(attachedTo: childAFlow.viewController))
        let childBInstance = try #require(attachmentManager.instance(attachedTo: childBFlow.viewController))
        let parentInstance = try #require(childAInstance.parent)

        parentFlow.coordinator.popToRoot()

        #expect(parentInstance.children.isEmpty)
        #expect(childAInstance.parent == nil)
        #expect(childBInstance.parent == nil)
    }

    @Test func stackFlow_popToRemovesLaterChildInstanceAndKeepsTargetInstance() throws {
        let attachmentManager = StateFlowInstanceAttachments()
        let childAFlow = makeInlineChildFlow(attachmentManager: attachmentManager)
        let childBFlow = makeInlineChildFlow(attachmentManager: attachmentManager)
        let composer = InstanceStackComposer(viewControllers: [
            .root: UIViewController(),
            .childA: childAFlow.viewController,
            .childB: childBFlow.viewController
        ])

        let parentFlow = Flow.stack(attachmentManager: attachmentManager, composer: composer) { router, composer in
            InstanceStackCoordinator(router: router, composer: composer)
        }
        parentFlow.coordinator.push(.childA)
        parentFlow.coordinator.push(.childB)

        let childAInstance = try #require(attachmentManager.instance(attachedTo: childAFlow.viewController))
        let childBInstance = try #require(attachmentManager.instance(attachedTo: childBFlow.viewController))
        let parentInstance = try #require(childAInstance.parent)

        parentFlow.coordinator.popTo(.childA)

        #expect(parentInstance.children.contains { $0 === childAInstance })
        #expect(!parentInstance.children.contains { $0 === childBInstance })
        #expect(childAInstance.parent === parentInstance)
        #expect(childBInstance.parent == nil)
    }

    @Test func stackFlow_setStackSynchronizesAdditionsAndRemovals() throws {
        let attachmentManager = StateFlowInstanceAttachments()
        let childAFlow = makeInlineChildFlow(attachmentManager: attachmentManager)
        let childBFlow = makeInlineChildFlow(attachmentManager: attachmentManager)
        let composer = InstanceStackComposer(viewControllers: [
            .root: UIViewController(),
            .childA: childAFlow.viewController,
            .childB: childBFlow.viewController
        ])

        let parentFlow = Flow.stack(attachmentManager: attachmentManager, composer: composer) { router, composer in
            InstanceStackCoordinator(router: router, composer: composer)
        }
        parentFlow.coordinator.push(.childA)

        let parentInstance = try #require(attachmentManager.instance(attachedTo: parentFlow.viewController))
        let childAInstance = try #require(attachmentManager.instance(attachedTo: childAFlow.viewController))
        let childBInstance = try #require(attachmentManager.instance(attachedTo: childBFlow.viewController))

        parentFlow.coordinator.setStack([.root, .childB])

        #expect(!parentInstance.children.contains { $0 === childAInstance })
        #expect(parentInstance.children.contains { $0 === childBInstance })
        #expect(childAInstance.parent == nil)
        #expect(childBInstance.parent === parentInstance)
    }

    @Test func stackFlow_popReleasesRemovedChildInstanceWhenNoExternalReferences() throws {
        let composer = EphemeralChildFlowComposer()
        let parentFlow = Flow.stack(composer: composer) { router, composer in
            InstanceStackCoordinator(router: router, composer: composer)
        }
        parentFlow.coordinator.push(.childA)

        let childLifetime = try makeLifetimeBoxes(from: composer.childAInstance)

        autoreleasepool {
            parentFlow.coordinator.pop()
        }

        #expect(childLifetime.instance.object == nil)
        #expect(childLifetime.router.object == nil)
        #expect(childLifetime.coordinator.object == nil)
    }

    @Test func stackFlow_setStackReleasesRemovedChildInstanceWhenNoExternalReferences() throws {
        let composer = EphemeralChildFlowComposer()
        let parentFlow = Flow.stack(composer: composer) { router, composer in
            InstanceStackCoordinator(router: router, composer: composer)
        }
        parentFlow.coordinator.push(.childA)

        let childLifetime = try makeLifetimeBoxes(from: composer.childAInstance)

        autoreleasepool {
            parentFlow.coordinator.setStack([.root])
        }

        #expect(childLifetime.instance.object == nil)
        #expect(childLifetime.router.object == nil)
        #expect(childLifetime.coordinator.object == nil)
    }

    @Test func tabFlow_setItemsSynchronizesAdditionsAndRemovals() throws {
        let attachmentManager = StateFlowInstanceAttachments()
        let childAFlow = makeInlineChildFlow(attachmentManager: attachmentManager)
        let childBFlow = makeInlineChildFlow(attachmentManager: attachmentManager)
        let composer = InstanceStackComposer(viewControllers: [
            .root: UIViewController(),
            .childA: childAFlow.viewController,
            .childB: childBFlow.viewController
        ])

        let parentFlow = Flow.tab(attachmentManager: attachmentManager, composer: composer) { router, composer in
            InstanceTabCoordinator(router: router, composer: composer)
        }
        let parentInstance = try #require(attachmentManager.instance(attachedTo: parentFlow.viewController))
        let childAInstance = try #require(attachmentManager.instance(attachedTo: childAFlow.viewController))
        let childBInstance = try #require(attachmentManager.instance(attachedTo: childBFlow.viewController))

        #expect(parentInstance.children.contains { $0 === childAInstance })

        parentFlow.coordinator.replaceTabs([.root, .childB])

        #expect(!parentInstance.children.contains { $0 === childAInstance })
        #expect(parentInstance.children.contains { $0 === childBInstance })
        #expect(childAInstance.parent == nil)
        #expect(childBInstance.parent === parentInstance)
    }

    @Test func tabFlow_setItemsReleasesRemovedChildFlowWhenNoExternalReferences() throws {
        let composer = EphemeralChildFlowComposer()
        let parentFlow = Flow.tab(composer: composer) { router, composer in
            InstanceTabCoordinator(router: router, composer: composer)
        }

        let weakChildViewController = WeakObjectBox(composer.childAViewController)
        let weakChildInstance = WeakObjectBox(composer.childAInstance as AnyObject?)

        autoreleasepool {
            parentFlow.coordinator.replaceTabs([.root])
        }

        #expect(weakChildViewController.object == nil)
        #expect(weakChildInstance.object == nil)
    }

    @Test func inlineFlow_pushAndPopSynchronizesChildInstance() throws {
        let attachmentManager = StateFlowInstanceAttachments()
        let childFlow = makeInlineChildFlow(attachmentManager: attachmentManager)
        let composer = InstanceStackComposer(viewControllers: [
            .root: UIViewController(),
            .childA: childFlow.viewController
        ])

        let parentFlow = Flow.inline(attachmentManager: attachmentManager, composer: composer) { router, composer in
            InstanceStackCoordinator(router: router, composer: composer)
        }
        let navigationController = UINavigationController(rootViewController: parentFlow.viewController)
        let parentInstance = try #require(attachmentManager.instance(attachedTo: parentFlow.viewController))
        let childInstance = try #require(attachmentManager.instance(attachedTo: childFlow.viewController))

        parentFlow.coordinator.push(.childA)

        #expect(navigationController.viewControllers.last === childFlow.viewController)
        #expect(parentInstance.children.contains { $0 === childInstance })
        #expect(childInstance.parent === parentInstance)

        parentFlow.coordinator.pop()

        #expect(!parentInstance.children.contains { $0 === childInstance })
        #expect(childInstance.parent == nil)
    }

    @Test func switchingFlow_switchToSynchronizesChildInstance() throws {
        let attachmentManager = StateFlowInstanceAttachments()
        let childAFlow = makeInlineChildFlow(attachmentManager: attachmentManager)
        let childBFlow = makeInlineChildFlow(attachmentManager: attachmentManager)
        let composer = InstanceStackComposer(viewControllers: [
            .root: UIViewController(),
            .childA: childAFlow.viewController,
            .childB: childBFlow.viewController
        ])

        let parentFlow = Flow.switching(attachmentManager: attachmentManager, composer: composer) { router, composer in
            InstanceSwitchCoordinator(router: router, composer: composer)
        }
        let parentInstance = try #require(attachmentManager.instance(attachedTo: parentFlow.viewController))
        let childAInstance = try #require(attachmentManager.instance(attachedTo: childAFlow.viewController))
        let childBInstance = try #require(attachmentManager.instance(attachedTo: childBFlow.viewController))

        parentFlow.coordinator.switchTo(.childA)

        #expect(parentInstance.children.contains { $0 === childAInstance })
        #expect(childAInstance.parent === parentInstance)

        parentFlow.coordinator.switchTo(.childB)

        #expect(!parentInstance.children.contains { $0 === childAInstance })
        #expect(parentInstance.children.contains { $0 === childBInstance })
        #expect(childAInstance.parent == nil)
        #expect(childBInstance.parent === parentInstance)
    }

    @Test func switchingFlow_embeddedInNavigationControllerReplacesStackItemWithoutReplacingWindowRoot() throws {
        let nextViewController = UIViewController()
        let composer = InstanceStackComposer(viewControllers: [
            .root: UIViewController(),
            .childA: nextViewController
        ])
        let parentFlow = Flow.switching(composer: composer) { router, composer in
            InstanceSwitchCoordinator(router: router, composer: composer)
        }
        let navigationController = UINavigationController(rootViewController: parentFlow.viewController)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        window.rootViewController = navigationController
        if parentFlow.viewController.view.window == nil {
            window.addSubview(parentFlow.viewController.view)
        }

        #expect(parentFlow.viewController.view.window === window)

        parentFlow.coordinator.switchTo(.childA)

        #expect(window.rootViewController === navigationController)
        #expect(navigationController.viewControllers.count == 1)
        #expect(navigationController.viewControllers.first === nextViewController)
    }

    @Test func switchingFlow_embeddedInTabBarControllerReplacesTabItemWithoutReplacingWindowRoot() throws {
        let nextViewController = UIViewController()
        let otherTabViewController = UIViewController()
        let composer = InstanceStackComposer(viewControllers: [
            .root: UIViewController(),
            .childA: nextViewController
        ])
        let parentFlow = Flow.switching(composer: composer) { router, composer in
            InstanceSwitchCoordinator(router: router, composer: composer)
        }
        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [parentFlow.viewController, otherTabViewController]
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        window.rootViewController = tabBarController
        if parentFlow.viewController.view.window == nil {
            window.addSubview(parentFlow.viewController.view)
        }

        #expect(parentFlow.viewController.view.window === window)

        parentFlow.coordinator.switchTo(.childA)

        let tabItems = try #require(tabBarController.viewControllers)
        #expect(window.rootViewController === tabBarController)
        #expect(tabItems.count == 2)
        #expect(tabItems.first === nextViewController)
        #expect(tabItems.last === otherTabViewController)
    }

    @Test func switchingFlow_keepsOldChildInstanceUntilTransitionCompletion() throws {
        let attachmentManager = StateFlowInstanceAttachments()
        let childAFlow = makeInlineChildFlow(attachmentManager: attachmentManager)
        let childBFlow = makeInlineChildFlow(attachmentManager: attachmentManager)
        let composer = InstanceStackComposer(viewControllers: [
            .root: UIViewController(),
            .childA: childAFlow.viewController,
            .childB: childBFlow.viewController
        ])
        let parentFlow = Flow.switching(attachmentManager: attachmentManager, composer: composer) { router, composer in
            InstanceSwitchCoordinator(router: router, composer: composer)
        }
        let parentInstance = try #require(attachmentManager.instance(attachedTo: parentFlow.viewController))
        let childAInstance = try #require(attachmentManager.instance(attachedTo: childAFlow.viewController))
        let childBInstance = try #require(attachmentManager.instance(attachedTo: childBFlow.viewController))

        parentFlow.coordinator.switchTo(.childA)

        #expect(parentInstance.children.contains { $0 === childAInstance })
        #expect(childAInstance.parent === parentInstance)

        let switchFacade = try #require(parentFlow.coordinator.router as? SwitchNavigationFacade)
        var transitionCompletion: (() -> Void)?
        var didCallUserCompletion = false
        switchFacade.setSwitchTransitionHandler { _, _, animated, completion in
            #expect(animated)
            transitionCompletion = completion
            return true
        }

        parentFlow.coordinator.switchTo(.childB, animated: true) {
            didCallUserCompletion = true
        }

        #expect(parentInstance.children.contains { $0 === childAInstance })
        #expect(parentInstance.children.contains { $0 === childBInstance })
        #expect(childAInstance.parent === parentInstance)
        #expect(childBInstance.parent === parentInstance)
        #expect(!didCallUserCompletion)

        let completeTransition = try #require(transitionCompletion)
        completeTransition()

        #expect(!parentInstance.children.contains { $0 === childAInstance })
        #expect(parentInstance.children.contains { $0 === childBInstance })
        #expect(childAInstance.parent == nil)
        #expect(childBInstance.parent === parentInstance)
        #expect(attachmentManager.instance(attachedTo: childAFlow.viewController) == nil)
        #expect(didCallUserCompletion)
    }

    @Test func switchingFlow_switchToReleasesRemovedChildInstanceWhenNoExternalReferences() throws {
        let composer = EphemeralChildFlowComposer()
        let parentFlow = Flow.switching(composer: composer) { router, composer in
            InstanceSwitchCoordinator(router: router, composer: composer)
        }
        let navigationController = UINavigationController(rootViewController: parentFlow.viewController)
        parentFlow.coordinator.switchTo(.childA)

        let childViewController = try #require(composer.childAViewController)
        let childLifetime = try makeLifetimeBoxes(from: composer.childAInstance)

        #expect(navigationController.viewControllers.last === childViewController)

        autoreleasepool {
            parentFlow.coordinator.switchTo(.root)
        }

        #expect(childLifetime.instance.object == nil)
        #expect(childLifetime.router.object == nil)
        #expect(childLifetime.coordinator.object == nil)
    }

    @Test func stackFlow_releasesInstanceCoordinatorAndRouterWhenRootViewControllerReleases() throws {
        weak var weakRootViewController: UIViewController?
        weak var weakInstance: (any FlowInstanceNode)?
        weak var weakCoordinator: AnyObject?
        weak var weakRouter: AnyObject?

        do {
            let composer = InstanceStackComposer(viewControllers: [
                .root: UIViewController()
            ])
            let flow = Flow.stack(composer: composer) { router, composer in
                InstanceStackCoordinator(router: router, composer: composer)
            }
            let instance = try #require(FlowInstanceAttachments.default.instance(attachedTo: flow.viewController))
            let router = try #require(object(named: "router", in: instance))
            let coordinator = try #require(object(named: "coordinator", in: instance))

            weakRootViewController = flow.viewController
            weakInstance = instance
            weakRouter = router
            weakCoordinator = coordinator

            #expect(weakRootViewController != nil)
            #expect(weakInstance != nil)
            #expect(weakRouter != nil)
            #expect(weakCoordinator != nil)
        }

        #expect(weakRootViewController == nil)
        #expect(weakInstance == nil)
        #expect(weakRouter == nil)
        #expect(weakCoordinator == nil)
    }

    @Test func stackFlow_nativeBackDelegatePopRemovesChildInstance() throws {
        let attachmentManager = StateFlowInstanceAttachments()
        let childFlow = makeInlineChildFlow(attachmentManager: attachmentManager)
        let composer = InstanceStackComposer(viewControllers: [
            .root: UIViewController(),
            .childA: childFlow.viewController
        ])

        let parentFlow = Flow.stack(attachmentManager: attachmentManager, composer: composer) { router, composer in
            InstanceStackCoordinator(router: router, composer: composer)
        }
        parentFlow.coordinator.push(.childA)

        let navigationController = try #require(parentFlow.viewController as? UINavigationController)
        let dispatcher = try #require(navigationController.delegate as? NavigationControllerDelegateDispatcher)
        let parentInstance = try #require(attachmentManager.instance(attachedTo: parentFlow.viewController))
        let childInstance = try #require(attachmentManager.instance(attachedTo: childFlow.viewController))

        navigationController.setViewControllers([composer.rootViewController], animated: false)
        dispatcher.navigationController(navigationController, didShow: composer.rootViewController, animated: false)

        #expect(!parentInstance.children.contains { $0 === childInstance })
        #expect(childInstance.parent == nil)
    }

    @Test func stackFlow_nativeBackInteractiveCancelDoesNotRemoveChildInstance() throws {
        let attachmentManager = StateFlowInstanceAttachments()
        let childFlow = makeInlineChildFlow(attachmentManager: attachmentManager)
        let composer = InstanceStackComposer(viewControllers: [
            .root: UIViewController(),
            .childA: childFlow.viewController
        ])

        let parentFlow = Flow.stack(attachmentManager: attachmentManager, composer: composer) { router, composer in
            InstanceStackCoordinator(router: router, composer: composer)
        }
        parentFlow.coordinator.push(.childA)

        let navigationController = try #require(parentFlow.viewController as? UINavigationController)
        let dispatcher = try #require(navigationController.delegate as? NavigationControllerDelegateDispatcher)
        let parentInstance = try #require(attachmentManager.instance(attachedTo: parentFlow.viewController))
        let childInstance = try #require(attachmentManager.instance(attachedTo: childFlow.viewController))

        dispatcher.navigationController(navigationController, didShow: childFlow.viewController, animated: true)

        #expect(parentInstance.children.contains { $0 === childInstance })
        #expect(childInstance.parent === parentInstance)
    }

    @Test func stackFlow_externalDidShowObservesInstanceAfterNativeBackCleanup() throws {
        let attachmentManager = StateFlowInstanceAttachments()
        let childFlow = makeInlineChildFlow(attachmentManager: attachmentManager)
        let externalDelegate = CapturingNavigationDelegate()
        let navigationController = UINavigationController()
        navigationController.delegate = externalDelegate
        let composer = InstanceStackComposer(viewControllers: [
            .root: UIViewController(),
            .childA: childFlow.viewController
        ])
        var parentInstance: (any FlowInstanceNode)?
        var childInstance: (any FlowInstanceNode)?
        var didInspectCleanupDuringExternalDidShow = false
        externalDelegate.onDidShow = { _, _, _ in
            guard let parentInstance, let childInstance else { return }

            didInspectCleanupDuringExternalDidShow = true
            #expect(!parentInstance.children.contains { $0 === childInstance })
            #expect(childInstance.parent == nil)
        }

        let parentFlow = Flow.stack(
            attachmentManager: attachmentManager,
            makeNavigationController: { navigationController },
            composer: composer
        ) { router, composer in
            InstanceStackCoordinator(router: router, composer: composer)
        }
        parentFlow.coordinator.push(.childA)
        let dispatcher = try #require(navigationController.delegate as? NavigationControllerDelegateDispatcher)
        parentInstance = attachmentManager.instance(attachedTo: navigationController)
        childInstance = attachmentManager.instance(attachedTo: childFlow.viewController)

        navigationController.setViewControllers([composer.rootViewController], animated: false)
        dispatcher.navigationController(navigationController, didShow: composer.rootViewController, animated: false)

        #expect(didInspectCleanupDuringExternalDidShow)
        #expect(externalDelegate.didShowCallCount == 1)
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
        let attachmentManager = StateFlowInstanceAttachments()
        let childFlow = makeInlineChildFlow(attachmentManager: attachmentManager)
        let composer = InstanceStackComposer(viewControllers: [
            .root: UIViewController(),
            .childA: childFlow.viewController
        ])

        let parentFlow = Flow.stack(attachmentManager: attachmentManager, composer: composer) { router, composer in
            InstanceStackCoordinator(router: router, composer: composer)
        }
        parentFlow.coordinator.push(.childA)

        let navigationController = try #require(parentFlow.viewController as? UINavigationController)
        let dispatcher = try #require(navigationController.delegate as? NavigationControllerDelegateDispatcher)
        let lookupCountBeforePop = attachmentManager.instancesLookupCount(attachedTo: childFlow.viewController)

        parentFlow.coordinator.pop()
        let lookupCountAfterPop = attachmentManager.instancesLookupCount(attachedTo: childFlow.viewController)
        dispatcher.navigationController(navigationController, didShow: composer.rootViewController, animated: false)

        #expect(lookupCountAfterPop == lookupCountBeforePop + 1)
        #expect(attachmentManager.instancesLookupCount(attachedTo: childFlow.viewController) == lookupCountAfterPop)
    }

    @Test func stackFlow_delegateProxyKeepsExistingExternalDelegate() throws {
        let attachmentManager = StateFlowInstanceAttachments()
        let externalDelegate = CapturingNavigationDelegate()
        let navigationController = UINavigationController()
        navigationController.delegate = externalDelegate
        let composer = InstanceStackComposer(viewControllers: [
            .root: UIViewController()
        ])

        let flow = Flow.stack(
            attachmentManager: attachmentManager,
            makeNavigationController: { navigationController },
            composer: composer
        ) { router, composer in
            InstanceStackCoordinator(router: router, composer: composer)
        }

        let dispatcher = try #require(navigationController.delegate as? NavigationControllerDelegateDispatcher)
        dispatcher.navigationController(navigationController, didShow: composer.rootViewController, animated: false)

        #expect(flow.viewController === navigationController)
        #expect(externalDelegate.didShowCallCount == 1)
    }

    @Test func stackFlow_delegateProxyReturnsExternalDelegateTransitionCallbacks() throws {
        let attachmentManager = StateFlowInstanceAttachments()
        let externalDelegate = CapturingNavigationDelegate()
        let animator = SentinelAnimator()
        let interactionController = SentinelInteractionController()
        externalDelegate.animator = animator
        externalDelegate.interactionController = interactionController
        let navigationController = UINavigationController()
        navigationController.delegate = externalDelegate
        let composer = InstanceStackComposer(viewControllers: [
            .root: UIViewController()
        ])

        _ = Flow.stack(
            attachmentManager: attachmentManager,
            makeNavigationController: { navigationController },
            composer: composer
        ) { router, composer in
            InstanceStackCoordinator(router: router, composer: composer)
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
        let attachmentManager = StateFlowInstanceAttachments()
        let externalDelegate = CapturingNavigationDelegate()
        externalDelegate.supportedOrientations = .portrait
        externalDelegate.preferredOrientation = .portraitUpsideDown
        let navigationController = UINavigationController()
        navigationController.delegate = externalDelegate
        let composer = InstanceStackComposer(viewControllers: [
            .root: UIViewController()
        ])

        _ = Flow.stack(
            attachmentManager: attachmentManager,
            makeNavigationController: { navigationController },
            composer: composer
        ) { router, composer in
            InstanceStackCoordinator(router: router, composer: composer)
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
