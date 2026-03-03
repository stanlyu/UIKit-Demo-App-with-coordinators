import Testing
import UIKit
@testable import Core

// MARK: - Shared Fixtures

/// Общий «пустой» composer для координаторов без маршрутов.
@MainActor
private final class NeverComposer: Composing {
    typealias Route = Never
    func makeViewController(for route: Never) -> UIViewController {}
}

/// Общий Route для родительских координаторов.
private enum ChildRoute { case child }

/// Дочерний координатор на InlineRouter — один VC, встраиваемый в чужой навигационный стек.
@MainActor
private final class ChildCoordinator: Coordinator<InlineRouter, Never> {
    var startCallCount = 0
    let rootVC = UIViewController()

    init() { super.init(composer: NeverComposer()) }

    override func start(_ capability: StartCapability) {
        startCallCount += 1
        router?.push(RouterItem(rootVC), animated: false, completion: nil)
    }
}

/// Composer, который при запросе `.child` создаёт дочерний координатор + InlineRouter
/// и возвращает `extractRootUI()`.
@MainActor
private final class ChildSpawningComposer<Route>: Composing where Route: Equatable {
    struct CreatedChild {
        weak var coordinator: ChildCoordinator?
        weak var router: InlineRouter?
    }

    private(set) var children: [CreatedChild] = []

    func makeViewController(for route: Route) -> UIViewController {
        let child = ChildCoordinator()
        let childRouter = InlineRouter(coordinator: child)
        children.append(CreatedChild(coordinator: child, router: childRouter))
        return childRouter.extractRootUI()
    }
}

// MARK: - ParentCoordinator (на реальном StackRouter)

/// Родительский координатор на реальном StackRouter.
@MainActor
private final class ParentCoordinator: Coordinator<StackRouter, ChildRoute> {
    convenience init() { self.init(composer: ChildSpawningComposer<ChildRoute>()) }

    override func start(_ capability: StartCapability) {}

    func pushChild() {
        let item = composer.makeItem(for: .child)
        router?.push(item, animated: false, completion: nil)
    }

    func popLast() {
        router?.pop(animated: false, completion: nil)
    }
}

/// Запускает ParentCoordinator через реальный StackRouter.
/// ВАЖНО: nav возвращается в тупле и ДОЛЖЕН удерживаться вызывающим,
/// иначе StackRouter теряет weak-ссылку на UINavigationController.
@MainActor
private func makeSUT() -> (
    parent: ParentCoordinator,
    nav: UINavigationController,
    composer: ChildSpawningComposer<ChildRoute>
) {
    let composer = ChildSpawningComposer<ChildRoute>()
    let parent = ParentCoordinator(composer: composer)
    let nav = UINavigationController()
    let router = StackRouter(coordinator: parent, navigationController: nav)
    _ = router.extractRootUI()
    return (parent, nav, composer)
}

// MARK: - Suite: Router Start

@MainActor
@Suite("Router — coordinator start lifecycle")
struct RouterStartTests {

    @Test func stackRouter_startsOnceAndInjectsRouter() {
        final class C: Coordinator<StackRouter, Never> {
            var count = 0
            init() { super.init(composer: NeverComposer()) }
            override func start(_ capability: StartCapability) { count += 1 }
        }
        let c = C()
        let nav = UINavigationController()
        let r = StackRouter(coordinator: c, navigationController: nav)
        _ = r.extractRootUI()
        _ = r.extractRootUI()
        #expect(c.count == 1)
        #expect(c.router === r)
        _ = nav
    }

    @Test func tabRouter_startsOnceAndInjectsRouter() {
        final class C: Coordinator<TabRouter, Never> {
            var count = 0
            init() { super.init(composer: NeverComposer()) }
            override func start(_ capability: StartCapability) { count += 1 }
        }
        let c = C()
        let r = TabRouter(coordinator: c)
        let root = r.extractRootUI()
        _ = r.extractRootUI()
        #expect(c.count == 1)
        #expect(c.router === r)
        _ = root
    }

    @Test func switchRouter_startsOnceAndInjectsRouter() {
        final class C: Coordinator<SwitchRouter, Never> {
            var count = 0
            init() { super.init(composer: NeverComposer()) }
            override func start(_ capability: StartCapability) {
                count += 1
                router?.setRoot(RouterItem(UIViewController()), animated: false, completion: nil)
            }
        }
        let c = C()
        let r = SwitchRouter(coordinator: c)
        let root = r.extractRootUI()
        _ = r.extractRootUI()
        #expect(c.count == 1)
        #expect(c.router === r)
        _ = root
    }

    @Test func inlineRouter_startsOnceAndInjectsRouter() {
        final class C: Coordinator<InlineRouter, Never> {
            var count = 0
            init() { super.init(composer: NeverComposer()) }
            override func start(_ capability: StartCapability) {
                count += 1
                router?.push(RouterItem(UIViewController()), animated: false, completion: nil)
            }
        }
        let c = C()
        let r = InlineRouter(coordinator: c)
        let root = r.extractRootUI()
        #expect(c.count == 1)
        #expect(c.router === r)
        _ = root
    }
}

// MARK: - Suite: Coordinator Label

@MainActor
@Suite("Coordinator — coordinatorLabel")
struct CoordinatorLabelTests {
    @Test func reflectsClassName() {
        let (parent, nav, _) = makeSUT()
        #expect(parent.coordinatorLabel == "ParentCoordinator")
        _ = nav
    }
}

// MARK: - Suite: Parent-Child через публичный API

@MainActor
@Suite("Coordinator Tree — parent-child via public API")
struct CoordinatorParentChildPublicTests {

    @Test func freshCoordinator_hasNoParentAndNoChildren() {
        let (parent, nav, _) = makeSUT()
        #expect(parent.parentCoordinator == nil)
        #expect(parent.childCoordinators.isEmpty)
        _ = nav
    }

    @Test func pushChild_linksIntoTree() {
        let (parent, nav, composer) = makeSUT()

        parent.pushChild()

        let child = composer.children.first?.coordinator
        #expect(parent.childCoordinators.count == 1)
        #expect(parent.childCoordinators.first === child)
        #expect(child?.parentCoordinator === parent)
        #expect(child?.startCallCount == 1)
        _ = nav
    }

    @Test func pushTwoChildren_bothLinkedIntoTree() {
        let (parent, nav, composer) = makeSUT()

        parent.pushChild()
        parent.pushChild()

        let child1 = composer.children[0].coordinator
        let child2 = composer.children[1].coordinator
        #expect(parent.childCoordinators.count == 2)
        #expect(child1?.parentCoordinator === parent)
        #expect(child2?.parentCoordinator === parent)
        _ = nav
    }
}

// MARK: - Suite: Internal addChild / removeChild

@MainActor
@Suite("Coordinator Tree — internal addChild / removeChild")
struct CoordinatorInternalTreeTests {

    @Test func addChild_linksParentAndAppearsInList() {
        let parent = makeParent()
        let child = makeParent()
        parent.addChild(child)
        #expect(parent.childCoordinators.first === child)
        #expect(child.parentCoordinator === parent)
    }

    @Test func addChild_idempotent() {
        let parent = makeParent()
        let child = makeParent()
        parent.addChild(child)
        parent.addChild(child)
        #expect(parent.childCoordinators.count == 1)
    }

    @Test func removeChild_unlinksFromListAndClearsParent() {
        let parent = makeParent()
        let child = makeParent()
        parent.addChild(child)
        parent.removeChild(child)
        #expect(parent.childCoordinators.isEmpty)
        #expect(child.parentCoordinator == nil)
    }

    /// Создаёт координатор без роутера — достаточно для тестирования addChild/removeChild.
    private func makeParent() -> ParentCoordinator {
        ParentCoordinator()
    }
}

// MARK: - Suite: Memory Management

@MainActor
@Suite("Coordinator Tree — memory management")
struct CoordinatorMemoryTests {

    /// При деаллокации дочернего координатора (deinit) он автоматически
    /// вызывает parent.removeChild(self) и пропадает из childCoordinators.
    @Test func childDeinit_removesFromParentTree() {
        let parent = ParentCoordinator()

        var child: ChildCoordinator? = ChildCoordinator()
        parent.addChild(child!)
        #expect(parent.childCoordinators.count == 1)

        child = nil // deinit → parent.removeChild(self)

        #expect(parent.childCoordinators.isEmpty, "deinit ребёнка должен удалить его из дерева родителя")
    }

    /// parent удерживает children через weak-ссылки. Деаллокация одного child
    /// оставляет остальных в дереве.
    @Test func deallocOneChild_leavesOthersIntact() {
        let parent = ParentCoordinator()
        let child1 = ChildCoordinator()
        var child2: ChildCoordinator? = ChildCoordinator()

        parent.addChild(child1)
        parent.addChild(child2!)
        #expect(parent.childCoordinators.count == 2)

        child2 = nil

        #expect(parent.childCoordinators.count == 1)
        #expect(parent.childCoordinators.first === child1)
        #expect(child1.parentCoordinator === parent)
    }

    /// parentCoordinator — weak. Деаллокация родителя обнуляет parentCoordinator у ребёнка.
    @Test func noRetainCycle_parentDeallocsCleanly() {
        var parent: ParentCoordinator? = ParentCoordinator()
        let child = ChildCoordinator()

        parent!.addChild(child)
        #expect(child.parentCoordinator === parent)

        weak var weakParent = parent
        parent = nil

        #expect(weakParent == nil, "parent должен деаллоцироваться — цикла нет")
        #expect(child.parentCoordinator == nil, "weak parentCoordinator должен обнулиться")
    }
}

