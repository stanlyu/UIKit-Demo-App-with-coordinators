import UIKit

@MainActor
public enum Flow {
    public static func stack<Coordinator, Composer>(
        makeNavigationController: @escaping @MainActor () -> UINavigationController = {
            UINavigationController()
        },
        composer: Composer,
        makeCoordinator: @MainActor (
            _ router: any StackNavigation,
            _ composer: Composer
        ) -> Coordinator
    ) -> CreatedFlow<Coordinator>
    where Coordinator: BaseCoordinator<any StackNavigation, Composer.Route>, Composer: Composing {
        let router = StackFlowRouter(makeNavigationController: makeNavigationController)
        let coordinator = makeCoordinator(router, composer)
        let runtime = FlowRuntime(router: router, coordinator: coordinator)
        let rootViewController = runtime.run()
        return CreatedFlow(viewController: rootViewController, coordinator: coordinator)
    }

    public static func tab<Coordinator, Composer>(
        makeTabBarController: @escaping @MainActor () -> UITabBarController = {
            UITabBarController()
        },
        composer: Composer,
        makeCoordinator: @MainActor (
            _ router: any TabNavigation,
            _ composer: Composer
        ) -> Coordinator
    ) -> CreatedFlow<Coordinator>
    where Coordinator: BaseCoordinator<any TabNavigation, Composer.Route>, Composer: Composing {
        let router = TabFlowRouter(makeTabBarController: makeTabBarController)
        let coordinator = makeCoordinator(router, composer)
        let runtime = FlowRuntime(router: router, coordinator: coordinator)
        let rootViewController = runtime.run()
        return CreatedFlow(viewController: rootViewController, coordinator: coordinator)
    }

    public static func inline<Coordinator, Composer>(
        composer: Composer,
        makeCoordinator: @MainActor (
            _ router: any StackNavigation,
            _ composer: Composer
        ) -> Coordinator
    ) -> CreatedFlow<Coordinator>
    where Coordinator: BaseCoordinator<any StackNavigation, Composer.Route>, Composer: Composing {
        let router = InlineFlowRouter()
        let coordinator = makeCoordinator(router, composer)
        let runtime = FlowRuntime(router: router, coordinator: coordinator)
        let rootViewController = runtime.run()
        return CreatedFlow(viewController: rootViewController, coordinator: coordinator)
    }

    public static func switching<Coordinator, Composer>(
        composer: Composer,
        makeCoordinator: @MainActor (
            _ router: any SwitchNavigation,
            _ composer: Composer
        ) -> Coordinator
    ) -> CreatedFlow<Coordinator>
    where Coordinator: BaseCoordinator<any SwitchNavigation, Composer.Route>, Composer: Composing {
        let router = SwitchFlowRouter()
        let coordinator = makeCoordinator(router, composer)
        let runtime = FlowRuntime(router: router, coordinator: coordinator)
        router.onRootChanged = { [weak runtime] newRoot in
            runtime?.attach(to: newRoot)
        }
        let rootViewController = runtime.run()
        return CreatedFlow(viewController: rootViewController, coordinator: coordinator)
    }
}
