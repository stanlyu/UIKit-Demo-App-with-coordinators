import Testing
import UIKit
import Core

@MainActor
@Suite("NavigationStackContext public API")
struct NavigationStackContextPublicAPITests {
    @Test func contextAcceptsOpaqueItemWithoutUIViewControllerAccess() {
        let context = PublicNavigationStackContextSpy()
        let flow = FlowBuilder.inline(
            composer: PublicNavigationStackItemTestComposer()
        ) { router, composer in
            PublicNavigationStackItemTestCoordinator(
                router: router,
                composer: composer,
                context: context
            )
        }
        var didCompletePush = false
        var didCompletePresent = false

        flow.coordinator.pushDetails(animated: true) {
            didCompletePush = true
        }
        flow.coordinator.presentDetails(animated: false) {
            didCompletePresent = true
        }

        #expect(context.pushCallCount == 1)
        #expect(context.presentCallCount == 1)
        #expect(context.lastPushAnimated == true)
        #expect(context.lastPresentAnimated == false)
        #expect(didCompletePush)
        #expect(didCompletePresent)
    }
}

private enum PublicNavigationStackItemTestRoute {
    case root
    case details
}

@MainActor
private struct PublicNavigationStackItemTestComposer: Composing {
    func makeViewController(for route: PublicNavigationStackItemTestRoute) -> UIViewController {
        UIViewController()
    }
}

@MainActor
private final class PublicNavigationStackItemTestCoordinator:
    BaseCoordinator<any StackNavigation, PublicNavigationStackItemTestRoute>
{
    init<C: Composing>(
        router: any StackNavigation,
        composer: C,
        context: any NavigationStackContext
    ) where C.Route == PublicNavigationStackItemTestRoute {
        self.context = context
        super.init(router: router, composer: composer)
    }

    override func start(_ context: CoordinatorStartContext) {
        router.setRoot(composer.makeItem(for: .root), animated: false)
    }

    func pushDetails(animated: Bool, completion: (() -> Void)?) {
        context.push(
            composer.makeItem(for: .details),
            animated: animated,
            completion: completion
        )
    }

    func presentDetails(animated: Bool, completion: (() -> Void)?) {
        context.present(
            composer.makeItem(for: .details),
            animated: animated,
            completion: completion
        )
    }

    private let context: any NavigationStackContext
}

@MainActor
private final class PublicNavigationStackContextSpy: NavigationStackContext {
    private(set) var pushCallCount = 0
    private(set) var presentCallCount = 0
    private(set) var lastPushAnimated: Bool?
    private(set) var lastPresentAnimated: Bool?

    func push(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        pushCallCount += 1
        lastPushAnimated = animated
        completion?()
    }

    func present(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        presentCallCount += 1
        lastPresentAnimated = animated
        completion?()
    }

    func push(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        pushCallCount += 1
        lastPushAnimated = animated
        completion?()
    }

    func present(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        presentCallCount += 1
        lastPresentAnimated = animated
        completion?()
    }
}
