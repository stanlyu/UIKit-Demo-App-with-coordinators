import UIKit

/// Точка входа для сборки flow: связывает роутер, координатор и узлы дерева в
/// единый объект `Flow`.
@MainActor
public enum FlowBuilder {
    /// Собирает flow с собственным `UINavigationController`.
    ///
    /// - Parameters:
    ///   - makeNavigationController: Фабрика навигационного контроллера; по
    ///     умолчанию создаёт пустой `UINavigationController`.
    ///   - composer: Компоузер, строящий экраны по маршрутам.
    ///   - makeCoordinator: Замыкание, создающее координатор из роутера и компоузера.
    /// - Returns: Собранный flow.
    public static func stack<Coordinator, Composer>(
        makeNavigationController: @escaping @MainActor () -> UINavigationController = {
            UINavigationController()
        },
        composer: Composer,
        makeCoordinator: @MainActor (
            _ router: any StackNavigation,
            _ composer: Composer
        ) -> Coordinator
    ) -> Flow<Coordinator>
    where Coordinator: BaseCoordinator<any StackNavigation, Composer.Route>, Composer: Composing {
        stack(
            attachmentStore: FlowInstanceAttachments.default,
            makeNavigationController: makeNavigationController,
            composer: composer,
            makeCoordinator: makeCoordinator
        )
    }

    /// Внутренняя перегрузка `stack` с подменяемым attachment store.
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
    ) -> Flow<Coordinator>
    where Coordinator: BaseCoordinator<any StackNavigation, Composer.Route>, Composer: Composing {
        let router = RouterProvider.stack(makeNavigationController: makeNavigationController)
        let coordinator = makeCoordinator(router, composer)

        let flowNodesManager = FlowNodesManager(coordinator: coordinator, attachmentStore: attachmentStore)
        router.setNodesManager(flowNodesManager)

        coordinator.start(CoordinatorStartContext())

        guard let rootVC = router.extractParentViewController() else {
            fatalError("StackRouter должен настроить родительский UIViewController")
        }
        return Flow(viewController: rootVC, coordinator: coordinator)
    }

    /// Собирает flow на базе `UITabBarController`.
    ///
    /// - Parameters:
    ///   - makeTabBarController: Фабрика контроллера вкладок; по умолчанию
    ///     создаёт пустой `UITabBarController`.
    ///   - composer: Компоузер, строящий экраны по маршрутам.
    ///   - makeCoordinator: Замыкание, создающее координатор из роутера и компоузера.
    /// - Returns: Собранный flow.
    public static func tab<Coordinator, Composer>(
        makeTabBarController: @escaping @MainActor () -> UITabBarController = {
            UITabBarController()
        },
        composer: Composer,
        makeCoordinator: @MainActor (
            _ router: any TabsNavigation,
            _ composer: Composer
        ) -> Coordinator
    ) -> Flow<Coordinator>
    where Coordinator: BaseCoordinator<any TabsNavigation, Composer.Route>, Composer: Composing {
        tab(
            attachmentStore: FlowInstanceAttachments.default,
            makeTabBarController: makeTabBarController,
            composer: composer,
            makeCoordinator: makeCoordinator
        )
    }

    /// Внутренняя перегрузка `tab` с подменяемым attachment store.
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
    ) -> Flow<Coordinator>
    where Coordinator: BaseCoordinator<any TabsNavigation, Composer.Route>, Composer: Composing {
        let router = RouterProvider.tabs(makeTabBarController: makeTabBarController)
        let coordinator = makeCoordinator(router, composer)

        let actualManager = FlowNodesManager(coordinator: coordinator, attachmentStore: attachmentStore)
        router.setNodesManager(actualManager)

        coordinator.start(CoordinatorStartContext())

        guard let rootVC = router.extractParentViewController() else {
            fatalError("TabsRouter должен настроить родительский UIViewController")
        }
        return Flow(viewController: rootVC, coordinator: coordinator)
    }

    /// Собирает flow, корнем которого является обычный `UIViewController`,
    /// встраиваемый в уже существующий навигационный стек.
    ///
    /// - Parameters:
    ///   - composer: Компоузер, строящий экраны по маршрутам.
    ///   - makeCoordinator: Замыкание, создающее координатор из роутера и компоузера.
    /// - Returns: Собранный flow.
    public static func inline<Coordinator, Composer>(
        composer: Composer,
        makeCoordinator: @MainActor (
            _ router: any StackNavigation,
            _ composer: Composer
        ) -> Coordinator
    ) -> Flow<Coordinator>
    where Coordinator: BaseCoordinator<any StackNavigation, Composer.Route>, Composer: Composing {
        inline(
            attachmentStore: FlowInstanceAttachments.default,
            composer: composer,
            makeCoordinator: makeCoordinator
        )
    }

    /// Внутренняя перегрузка `inline` с подменяемым attachment store.
    static func inline<Coordinator, Composer>(
        attachmentStore: any FlowInstanceAttachmentStoring,
        composer: Composer,
        makeCoordinator: @MainActor (
            _ router: any StackNavigation,
            _ composer: Composer
        ) -> Coordinator
    ) -> Flow<Coordinator>
    where Coordinator: BaseCoordinator<any StackNavigation, Composer.Route>, Composer: Composing {
        let router = RouterProvider.inline()
        let coordinator = makeCoordinator(router, composer)

        let flowNodesManager = FlowNodesManager(coordinator: coordinator, attachmentStore: attachmentStore)
        router.setNodesManager(flowNodesManager)

        coordinator.start(CoordinatorStartContext())

        guard let rootVC = router.extractParentViewController() else {
            fatalError("Координатор должен установить корневой контент (setRoot) во время start(_:).")
        }

        return Flow(viewController: rootVC, coordinator: coordinator)
    }

    /// Собирает flow, корень которого полностью заменяется при переключении
    /// (одновременно активен только один экран).
    ///
    /// - Parameters:
    ///   - composer: Компоузер, строящий экраны по маршрутам.
    ///   - makeCoordinator: Замыкание, создающее координатор из роутера и компоузера.
    /// - Returns: Собранный flow.
    public static func switching<Coordinator, Composer>(
        composer: Composer,
        makeCoordinator: @MainActor (
            _ router: any SwitchNavigation,
            _ composer: Composer
        ) -> Coordinator
    ) -> Flow<Coordinator>
    where Coordinator: BaseCoordinator<any SwitchNavigation, Composer.Route>, Composer: Composing {
        switching(
            attachmentStore: FlowInstanceAttachments.default,
            composer: composer,
            makeCoordinator: makeCoordinator
        )
    }

    /// Внутренняя перегрузка `switching` с подменяемым attachment store.
    static func switching<Coordinator, Composer>(
        attachmentStore: any FlowInstanceAttachmentStoring,
        composer: Composer,
        makeCoordinator: @MainActor (
            _ router: any SwitchNavigation,
            _ composer: Composer
        ) -> Coordinator
    ) -> Flow<Coordinator>
    where Coordinator: BaseCoordinator<any SwitchNavigation, Composer.Route>, Composer: Composing {
        let router = RouterProvider.switch()
        let coordinator = makeCoordinator(router, composer)

        let flowNodesManager = FlowNodesManager(coordinator: coordinator, attachmentStore: attachmentStore)
        router.setNodesManager(flowNodesManager)

        coordinator.start(CoordinatorStartContext())

        guard let rootVC = router.extractParentViewController() else {
            fatalError("Координатор должен установить корневой контент (switchTo) во время start(_:).")
        }

        return Flow(viewController: rootVC, coordinator: coordinator)
    }
}
