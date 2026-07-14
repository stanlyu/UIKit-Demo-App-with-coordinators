import UIKit

/// Точка входа для сборки flow новой архитектуры.
///
/// Снаружи модуль выбирает тип контейнера, передает composer и создает координатор.
/// Core сам создает `FlowInstance`, привязывает его к root `UIViewController`
/// и скрывает lifecycle API от feature-кода.
@MainActor
public enum Flow {
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
            attachmentManager: FlowInstanceAttachments.default,
            makeNavigationController: makeNavigationController,
            composer: composer,
            makeCoordinator: makeCoordinator
        )
    }

    /// Тестовая перегрузка с подменяемым attachment store.
    internal static func stack<Coordinator, Composer>(
        attachmentManager: any FlowInstanceAttachmentStoring,
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
        let instance = FlowInstance(
            router: router,
            coordinator: coordinator,
            attachmentStore: attachmentManager
        )
        let rootViewController = instance.run()
        return CreatedFlow(viewController: rootViewController, coordinator: coordinator)
    }

    /// Собирает flow на базе `UITabBarController`.
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
            attachmentManager: FlowInstanceAttachments.default,
            makeTabBarController: makeTabBarController,
            composer: composer,
            makeCoordinator: makeCoordinator
        )
    }

    /// Тестовая перегрузка с подменяемым attachment store.
    internal static func tab<Coordinator, Composer>(
        attachmentManager: any FlowInstanceAttachmentStoring,
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
        let router = FlowRouter<UITabBarController, TabNavigationDriver>(
            makeTabBarController: makeTabBarController,
            attachmentManager: attachmentManager
        )
        let navigation = TabNavigationFacade(router: router)
        let coordinator = makeCoordinator(navigation, composer)
        coordinator.setAttachmentManager(attachmentManager)
        let instance = FlowInstance(
            router: router,
            coordinator: coordinator,
            attachmentStore: attachmentManager
        )
        let rootViewController = instance.run()
        return CreatedFlow(viewController: rootViewController, coordinator: coordinator)
    }

    /// Собирает flow, root которого является обычным `UIViewController`.
    ///
    /// Такой flow может жить внутри чужого navigation stack и управлять только
    /// своей частью стека.
    public static func inline<Coordinator, Composer>(
        composer: Composer,
        makeCoordinator: @MainActor (
            _ router: any StackNavigation,
            _ composer: Composer
        ) -> Coordinator
    ) -> CreatedFlow<Coordinator>
    where Coordinator: BaseCoordinator<any StackNavigation, Composer.Route>, Composer: Composing {
        inline(
            attachmentManager: FlowInstanceAttachments.default,
            composer: composer,
            makeCoordinator: makeCoordinator
        )
    }

    /// Тестовая перегрузка с подменяемым attachment store.
    internal static func inline<Coordinator, Composer>(
        attachmentManager: any FlowInstanceAttachmentStoring,
        composer: Composer,
        makeCoordinator: @MainActor (
            _ router: any StackNavigation,
            _ composer: Composer
        ) -> Coordinator
    ) -> CreatedFlow<Coordinator>
    where Coordinator: BaseCoordinator<any StackNavigation, Composer.Route>, Composer: Composing {
        let router = FlowRouter<UIViewController, InlineNavigationDriver>(
            attachmentManager: attachmentManager
        )
        let navigation = InlineNavigationFacade(router: router)
        let coordinator = makeCoordinator(navigation, composer)
        coordinator.setAttachmentManager(attachmentManager)
        let instance = FlowInstance(
            router: router,
            coordinator: coordinator,
            attachmentStore: attachmentManager
        )
        let rootViewController = instance.run()
        return CreatedFlow(viewController: rootViewController, coordinator: coordinator)
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
            attachmentManager: FlowInstanceAttachments.default,
            composer: composer,
            makeCoordinator: makeCoordinator
        )
    }

    /// Тестовая перегрузка с подменяемым attachment store.
    internal static func switching<Coordinator, Composer>(
        attachmentManager: any FlowInstanceAttachmentStoring,
        composer: Composer,
        makeCoordinator: @MainActor (
            _ router: any SwitchNavigation,
            _ composer: Composer
        ) -> Coordinator
    ) -> CreatedFlow<Coordinator>
    where Coordinator: BaseCoordinator<any SwitchNavigation, Composer.Route>, Composer: Composing {
        let router = FlowRouter<UIViewController, SwitchNavigationDriver>(
            attachmentManager: attachmentManager
        )
        let navigation = SwitchNavigationFacade(router: router)
        let coordinator = makeCoordinator(navigation, composer)
        coordinator.setAttachmentManager(attachmentManager)
        let instance = FlowInstance(
            router: router,
            coordinator: coordinator,
            attachmentStore: attachmentManager
        )
        let rootViewController = instance.run()
        return CreatedFlow(viewController: rootViewController, coordinator: coordinator)
    }
}
