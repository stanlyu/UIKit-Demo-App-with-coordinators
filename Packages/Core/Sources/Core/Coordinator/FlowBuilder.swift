import UIKit

@MainActor
public enum FlowBuilder {
    /// Собирает flow с собственным `UINavigationController`.
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
            attachmentStore: FlowInstanceAttachments.default,
            makeNavigationController: makeNavigationController,
            composer: composer,
            makeCoordinator: makeCoordinator
        )
    }

    /// Тестовая перегрузка с подменяемым attachment store.
    static func stack<Coordinator, Composer>(
        attachmentStore: any FlowInstanceAttachmentStoring,
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
        let router = StackRouter(makeNavigationController: makeNavigationController)
        let coordinator = makeCoordinator(router, composer)

        let flowNodesManager = FlowNodesManager(coordinator: coordinator, attachmentStore: attachmentStore)
        router.setNodesManager(flowNodesManager)
        flowNodesManager.setRootViewController(router.navigationController)

        coordinator.start(CoordinatorStartContext())

        return CreatedFlow(viewController: router.navigationController, coordinator: coordinator)
    }

    /// Собирает flow на базе `UITabBarController`.
    public static func tab<Coordinator, Composer>(
        makeTabBarController: @escaping @MainActor () -> UITabBarController = {
            UITabBarController()
        },
        composer: Composer,
        makeCoordinator: @MainActor (
            _ router: any TabsNavigation,
            _ composer: Composer
        ) -> Coordinator
    ) -> CreatedFlow<Coordinator>
    where Coordinator: BaseCoordinator<any TabsNavigation, Composer.Route>, Composer: Composing {
        tab(
            attachmentStore: FlowInstanceAttachments.default,
            makeTabBarController: makeTabBarController,
            composer: composer,
            makeCoordinator: makeCoordinator
        )
    }

    /// Тестовая перегрузка с подменяемым attachment store.
    static func tab<Coordinator, Composer>(
        attachmentStore: any FlowInstanceAttachmentStoring,
        makeTabBarController: @escaping @MainActor () -> UITabBarController = {
            UITabBarController()
        },
        composer: Composer,
        makeCoordinator: @MainActor (
            _ router: any TabsNavigation,
            _ composer: Composer
        ) -> Coordinator
    ) -> CreatedFlow<Coordinator>
    where Coordinator: BaseCoordinator<any TabsNavigation, Composer.Route>, Composer: Composing {
        let router = TabsRouter(makeTabBarController: makeTabBarController)
        let coordinator = makeCoordinator(router, composer)

        let actualManager = FlowNodesManager(coordinator: coordinator, attachmentStore: attachmentStore)
        router.setNodesManager(actualManager)
        actualManager.setRootViewController(router.tabBarController)

        coordinator.start(CoordinatorStartContext())

        return CreatedFlow(viewController: router.tabBarController, coordinator: coordinator)
    }

    /// Собирает flow, root которого является обычным `UIViewController`.
    public static func inline<Coordinator, Composer>(
        composer: Composer,
        makeCoordinator: @MainActor (
            _ router: any StackNavigation,
            _ composer: Composer
        ) -> Coordinator
    ) -> CreatedFlow<Coordinator>
    where Coordinator: BaseCoordinator<any StackNavigation, Composer.Route>, Composer: Composing {
        inline(
            attachmentStore: FlowInstanceAttachments.default,
            composer: composer,
            makeCoordinator: makeCoordinator
        )
    }

    /// Тестовая перегрузка с подменяемым attachment store.
    static func inline<Coordinator, Composer>(
        attachmentStore: any FlowInstanceAttachmentStoring,
        composer: Composer,
        makeCoordinator: @MainActor (
            _ router: any StackNavigation,
            _ composer: Composer
        ) -> Coordinator
    ) -> CreatedFlow<Coordinator>
    where Coordinator: BaseCoordinator<any StackNavigation, Composer.Route>, Composer: Composing {
        let router = InlineRouter()
        let coordinator = makeCoordinator(router, composer)

        let flowNodesManager = FlowNodesManager(coordinator: coordinator, attachmentStore: attachmentStore)
        router.setNodesManager(flowNodesManager)

        coordinator.start(CoordinatorStartContext())

        guard let rootVC = router.rootViewController else {
            fatalError("Coordinator must set root content (setRoot) during start(_:).")
        }

        flowNodesManager.setRootViewController(rootVC)
        router.updateRootViewController(rootVC)

        return CreatedFlow(viewController: rootVC, coordinator: coordinator)
    }

    /// Собирает flow, который заменяет текущий root content целиком.
    public static func switching<Coordinator, Composer>(
        composer: Composer,
        makeCoordinator: @MainActor (
            _ router: any SwitchNavigation,
            _ composer: Composer
        ) -> Coordinator
    ) -> CreatedFlow<Coordinator>
    where Coordinator: BaseCoordinator<any SwitchNavigation, Composer.Route>, Composer: Composing {
        switching(
            attachmentStore: FlowInstanceAttachments.default,
            composer: composer,
            makeCoordinator: makeCoordinator
        )
    }

    /// Тестовая перегрузка с подменяемым attachment store.
    static func switching<Coordinator, Composer>(
        attachmentStore: any FlowInstanceAttachmentStoring,
        composer: Composer,
        makeCoordinator: @MainActor (
            _ router: any SwitchNavigation,
            _ composer: Composer
        ) -> Coordinator
    ) -> CreatedFlow<Coordinator>
    where Coordinator: BaseCoordinator<any SwitchNavigation, Composer.Route>, Composer: Composing {
        let router = SwitchRouter()
        let coordinator = makeCoordinator(router, composer)

        let flowNodesManager = FlowNodesManager(coordinator: coordinator, attachmentStore: attachmentStore)
        router.setNodesManager(flowNodesManager)

        coordinator.start(CoordinatorStartContext())

        guard let rootVC = router.rootViewController else {
            fatalError("Coordinator must set root content (switchTo) during start(_:).")
        }

        flowNodesManager.setRootViewController(rootVC)

        return CreatedFlow(viewController: rootVC, coordinator: coordinator)
    }
}
