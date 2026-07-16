import Testing
import UIKit
@testable import Core

// MARK: - Tags

extension Tag {
    // Дерево flow-узлов и синхронизация связей «родитель — ребёнок».
    @Tag static var tree: Tag
    // Навигационные роутеры (stack/inline/tabs/switch).
    @Tag static var routing: Tag
    // Сборка flow из роутера, координатора и узлов дерева.
    @Tag static var flowBuilding: Tag
}

// MARK: - FlowNode

@MainActor
@Suite("FlowNode Tests")
struct FlowNodeTests {
    @Test(.tags(.tree)) func nodeStoresCoordinatorOnInit() {
        // arrange
        let coordinator = StubCoordinator()

        // act
        let node = FlowNode(coordinator: coordinator)

        // assert
        #expect(node.coordinator === coordinator)
    }

    @Test(.tags(.tree)) func nodeHasNoParentAndChildrenOnInit() {
        // arrange
        let coordinator = StubCoordinator()

        // act
        let node = FlowNode(coordinator: coordinator)

        // assert
        #expect(node.parent == nil)
        #expect(node.children.isEmpty)
    }

    @Test(.tags(.tree)) func adoptSetsParentAndAppendsChild() {
        // arrange
        let parent = FlowNode(coordinator: StubCoordinator())
        let child = FlowNode(coordinator: StubCoordinator())

        // act
        parent.adopt(child)

        // assert
        #expect(child.parent === parent)
        #expect(parent.children.count == 1)
        #expect(parent.children.first === child)
    }

    @Test(.tags(.tree)) func removeChildClearsParentAndChildren() {
        // arrange
        let parent = FlowNode(coordinator: StubCoordinator())
        let child = FlowNode(coordinator: StubCoordinator())
        parent.adopt(child)

        // act
        parent.removeChild(child)

        // assert
        #expect(child.parent == nil)
        #expect(parent.children.isEmpty)
    }
}

// MARK: - FlowNodesManager

@MainActor
@Suite("FlowNodesManager Tests")
struct FlowNodesManagerTests {
    @Test(.tags(.tree)) func updateChildViewControllersAdoptsChildNode() {
        // arrange
        let store = AssociatedObjectFlowInstanceAttachmentStore()
        let parentVC = UIViewController()
        let childVC = UIViewController()
        let parentManager = FlowNodesManager(coordinator: StubCoordinator(), attachmentStore: store)
        parentManager.attach(to: parentVC)
        let childManager = FlowNodesManager(coordinator: StubCoordinator(), attachmentStore: store)
        childManager.attach(to: childVC)

        // act
        parentManager.updateChildViewControllers([childVC])

        // assert
        #expect(childManager.node.parent === parentManager.node)
        #expect(parentManager.node.children.contains { $0 === childManager.node })
    }

    @Test(.tags(.tree)) func updateChildViewControllersRemovesDetachedChildNode() {
        // arrange
        let store = AssociatedObjectFlowInstanceAttachmentStore()
        let parentVC = UIViewController()
        let childVC = UIViewController()
        let parentManager = FlowNodesManager(coordinator: StubCoordinator(), attachmentStore: store)
        parentManager.attach(to: parentVC)
        let childManager = FlowNodesManager(coordinator: StubCoordinator(), attachmentStore: store)
        childManager.attach(to: childVC)
        parentManager.updateChildViewControllers([childVC])

        // act
        parentManager.updateChildViewControllers([])

        // assert
        #expect(childManager.node.parent == nil)
        #expect(!parentManager.node.children.contains { $0 === childManager.node })
    }
}

// MARK: - StackRouter

@MainActor
@Suite("StackRouter Tests")
struct StackRouterTests {
    @Test(.tags(.routing)) func setRootSetsSingleItem() {
        // arrange
        let sut = makeSUT()
        let item = RouterItem(UIViewController())

        // act
        sut.router.setRoot(item, animated: false)

        // assert
        #expect(sut.router.items.count == 1)
        #expect(sut.router.items.first?.viewController === item.viewController)
    }

    @Test(.tags(.routing)) func pushAppendsItem() {
        // arrange
        let sut = makeSUT()
        sut.router.setRoot(RouterItem(UIViewController()), animated: false)
        let pushed = RouterItem(UIViewController())

        // act
        sut.router.push(pushed, animated: false, completion: nil)

        // assert
        #expect(sut.router.items.count == 2)
        #expect(sut.router.items.last?.viewController === pushed.viewController)
    }

    @Test(.tags(.routing)) func popRemovesLastItem() {
        // arrange
        let sut = makeSUT()
        sut.router.setRoot(RouterItem(UIViewController()), animated: false)
        sut.router.push(RouterItem(UIViewController()), animated: false, completion: nil)

        // act
        sut.router.pop(animated: false, completion: nil)

        // assert
        #expect(sut.router.items.count == 1)
    }
}

// MARK: - InlineRouter

@MainActor
@Suite("InlineRouter Tests")
struct InlineRouterTests {
    @Test(.tags(.routing)) func setRootSetsSingleItem() {
        // arrange
        let sut = makeSUT()
        let item = RouterItem(UIViewController())

        // act
        sut.embedAndSetRoot(item)

        // assert
        #expect(sut.router.items.count == 1)
        #expect(sut.router.items.first?.viewController === item.viewController)
    }

    @Test(.tags(.routing)) func pushAppendsItem() {
        // arrange
        let sut = makeSUT()
        sut.embedAndSetRoot(RouterItem(UIViewController()))
        let pushed = RouterItem(UIViewController())

        // act
        sut.router.push(pushed, animated: false, completion: nil)

        // assert
        #expect(sut.router.items.count == 2)
        #expect(sut.router.items.last?.viewController === pushed.viewController)
    }

    @Test(.tags(.routing)) func popRemovesLastItem() {
        // arrange
        let sut = makeSUT()
        sut.embedAndSetRoot(RouterItem(UIViewController()))
        sut.router.push(RouterItem(UIViewController()), animated: false, completion: nil)

        // act
        sut.router.pop(animated: false, completion: nil)

        // assert
        #expect(sut.router.items.count == 1)
    }
}

// MARK: - TabsRouter

@MainActor
@Suite("TabsRouter Tests")
struct TabsRouterTests {
    @Test(.tags(.routing)) func setItemsPopulatesTabBarAndSelectsFirst() {
        // arrange
        let sut = makeSUT()
        let items = [RouterItem(UIViewController()), RouterItem(UIViewController())]

        // act
        sut.router.setItems(items, animated: false)

        // assert
        #expect(sut.tabController.viewControllers?.count == 2)
        #expect(sut.router.selectedIndex == 0)
    }

    @Test(.tags(.routing)) func selectTabChangesSelectedIndex() {
        // arrange
        let sut = makeSUT()
        sut.router.setItems([RouterItem(UIViewController()), RouterItem(UIViewController())], animated: false)

        // act
        sut.router.selectTab(at: 1)

        // assert
        #expect(sut.router.selectedIndex == 1)
    }
}

// MARK: - SwitchRouter

@MainActor
@Suite("SwitchRouter Tests")
struct SwitchRouterTests {
    @Test(.tags(.routing)) func switchToSetsCurrentItem() {
        // arrange
        let sut = makeSUT()
        let item = RouterItem(UIViewController())

        // act
        sut.router.switchTo(item, animated: false, completion: nil)

        // assert
        #expect(sut.router.currentItem?.viewController === item.viewController)
    }

    @Test(.tags(.routing)) func switchToReplacesCurrentItem() {
        // arrange
        let sut = makeSUT()
        sut.router.switchTo(RouterItem(UIViewController()), animated: false, completion: nil)
        let next = RouterItem(UIViewController())

        // act
        sut.router.switchTo(next, animated: false, completion: nil)

        // assert
        #expect(sut.router.currentItem?.viewController === next.viewController)
    }
}

// MARK: - FlowBuilder

@MainActor
@Suite("FlowBuilder Tests")
struct FlowBuilderTests {
    @Test(.tags(.flowBuilding)) func buildStackProducesNavigationControllerWithComposerRoot() {
        // arrange
        let composer = TestComposer()

        // act
        let flow = FlowBuilder.stack(composer: composer) { router, composer in
            TestStackCoordinator(router: router, composer: composer)
        }

        // assert
        #expect(flow.viewController is UINavigationController)
        #expect(type(of: flow.coordinator) == TestStackCoordinator.self)
        #expect((flow.viewController as? UINavigationController)?.viewControllers.first === composer.rootVC)
    }
}

// MARK: - Router test doubles and helpers

// Минимальный тестовый координатор-заглушка, соответствующий `Coordinating`.
// Используется вместо `NSObject` там, где требуется `any Coordinating`.
@MainActor
private final class StubCoordinator: Coordinating {}

// Создаёт менеджер узлов с собственным attachment store. Общий setup для
// router-тестов: каждый роутер получает независимое дерево flow-узлов.
@MainActor
private func makeFlowNodesManager() -> FlowNodesManager {
    let store = AssociatedObjectFlowInstanceAttachmentStore()
    let coordinator = StubCoordinator()
    return FlowNodesManager(coordinator: coordinator, attachmentStore: store)
}

private extension StackRouterTests {
    @MainActor
    struct SUT {
        let router: StackNavigation & FlowLifecycleRouter
        let nav: UINavigationController
    }

    @MainActor
    func makeSUT() -> SUT {
        let manager = makeFlowNodesManager()
        let nav = UINavigationController()
        let router = RouterProvider.stack(makeNavigationController: { nav })
        router.setNodesManager(manager)
        manager.attach(to: nav)
        return SUT(router: router, nav: nav)
    }
}

private extension InlineRouterTests {
    @MainActor
    struct SUT {
        let router: StackNavigation & FlowLifecycleRouter
        let nav: UINavigationController

        // Встраивает элемент во внешний nav и делает его корнем inline-flow.
        // InlineRouter управляет частью существующего стека, поэтому корневой
        // контроллер сначала должен оказаться в `nav`.
        func embedAndSetRoot(_ item: RouterItem) {
            nav.setViewControllers([item.viewController], animated: false)
            router.setRoot(item, animated: false)
        }
    }

    @MainActor
    func makeSUT() -> SUT {
        let manager = makeFlowNodesManager()
        let nav = UINavigationController()
        let router = RouterProvider.inline()
        router.setNodesManager(manager)
        return SUT(router: router, nav: nav)
    }
}

private extension TabsRouterTests {
    @MainActor
    struct SUT {
        let router: TabsNavigation & FlowLifecycleRouter
        let tabController: UITabBarController
    }

    @MainActor
    func makeSUT() -> SUT {
        let manager = makeFlowNodesManager()
        let tabController = UITabBarController()
        let router = RouterProvider.tabs(makeTabBarController: { tabController })
        router.setNodesManager(manager)
        return SUT(router: router, tabController: tabController)
    }
}

private extension SwitchRouterTests {
    @MainActor
    struct SUT {
        let router: SwitchNavigation & FlowLifecycleRouter
    }

    @MainActor
    func makeSUT() -> SUT {
        let manager = makeFlowNodesManager()
        let router = RouterProvider.switch()
        router.setNodesManager(manager)
        return SUT(router: router)
    }
}

// MARK: - FlowBuilder test doubles

private enum TestRoute {
    case root
    case details
}

@MainActor
private final class TestComposer: Composing {
    typealias Route = TestRoute

    let rootVC = UIViewController()
    let detailsVC = UIViewController()

    func makeViewController(for route: TestRoute) -> UIViewController {
        switch route {
        case .root: return rootVC
        case .details: return detailsVC
        }
    }
}

@MainActor
private final class TestStackCoordinator: BaseCoordinator<any StackNavigation, TestRoute> {
    override func start(_ context: CoordinatorStartContext) {
        router.setRoot(composer.makeItem(for: .root), animated: false)
    }
}
