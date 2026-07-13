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
        stack(
            attachmentManager: FlowAttachmentManager.default,
            makeNavigationController: makeNavigationController,
            composer: composer,
            makeCoordinator: makeCoordinator
        )
    }

    internal static func stack<Coordinator, Composer>(
        attachmentManager: any FlowAttachmentManaging,
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
        let router = FlowRouter<UINavigationController, StackNavigationDriver>(
            makeNavigationController: makeNavigationController,
            attachmentManager: attachmentManager
        )
        let navigation = StackNavigationFacade(router: router)
        let coordinator = makeCoordinator(navigation, composer)
        coordinator.setAttachmentManager(attachmentManager)
        let runtime = FlowRuntime(
            router: router,
            coordinator: coordinator,
            attachmentManager: attachmentManager
        )
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
        tab(
            attachmentManager: FlowAttachmentManager.default,
            makeTabBarController: makeTabBarController,
            composer: composer,
            makeCoordinator: makeCoordinator
        )
    }

    internal static func tab<Coordinator, Composer>(
        attachmentManager: any FlowAttachmentManaging,
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
        coordinator.setAttachmentManager(attachmentManager)
        let runtime = FlowRuntime(
            router: router,
            coordinator: coordinator,
            attachmentManager: attachmentManager
        )
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
        inline(
            attachmentManager: FlowAttachmentManager.default,
            composer: composer,
            makeCoordinator: makeCoordinator
        )
    }

    internal static func inline<Coordinator, Composer>(
        attachmentManager: any FlowAttachmentManaging,
        composer: Composer,
        makeCoordinator: @MainActor (
            _ router: any StackNavigation,
            _ composer: Composer
        ) -> Coordinator
    ) -> CreatedFlow<Coordinator>
    where Coordinator: BaseCoordinator<any StackNavigation, Composer.Route>, Composer: Composing {
        let router = InlineFlowRouter()
        let coordinator = makeCoordinator(router, composer)
        coordinator.setAttachmentManager(attachmentManager)
        let runtime = FlowRuntime(
            router: router,
            coordinator: coordinator,
            attachmentManager: attachmentManager
        )
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
        switching(
            attachmentManager: FlowAttachmentManager.default,
            composer: composer,
            makeCoordinator: makeCoordinator
        )
    }

    internal static func switching<Coordinator, Composer>(
        attachmentManager: any FlowAttachmentManaging,
        composer: Composer,
        makeCoordinator: @MainActor (
            _ router: any SwitchNavigation,
            _ composer: Composer
        ) -> Coordinator
    ) -> CreatedFlow<Coordinator>
    where Coordinator: BaseCoordinator<any SwitchNavigation, Composer.Route>, Composer: Composing {
        let router = SwitchFlowRouter()
        let coordinator = makeCoordinator(router, composer)
        coordinator.setAttachmentManager(attachmentManager)
        let runtime = FlowRuntime(
            router: router,
            coordinator: coordinator,
            attachmentManager: attachmentManager
        )
        router.onRootChanged = { [weak runtime] newRoot in
            runtime?.attach(to: newRoot)
        }
        let rootViewController = runtime.run()
        return CreatedFlow(viewController: rootViewController, coordinator: coordinator)
    }
}
