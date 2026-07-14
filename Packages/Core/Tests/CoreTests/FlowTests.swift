import Testing
import UIKit
@testable import Core

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

@MainActor
@Suite("FlowNode Tests")
struct FlowNodeTests {
    @Test func nodeCreationAndAdoption() {
        let rootCoordinator = NSObject()
        let childCoordinator = NSObject()
        
        let rootNode = FlowNode(coordinator: rootCoordinator)
        let childNode = FlowNode(coordinator: childCoordinator)
        
        #expect(rootNode.coordinator === rootCoordinator)
        #expect(childNode.coordinator === childCoordinator)
        #expect(rootNode.parent == nil)
        #expect(rootNode.children.isEmpty)
        
        rootNode.adopt(childNode)
        
        #expect(childNode.parent === rootNode)
        #expect(rootNode.children.count == 1)
        #expect(rootNode.children.first === childNode)
        
        rootNode.removeChild(childNode)
        
        #expect(childNode.parent == nil)
        #expect(rootNode.children.isEmpty)
    }
}

@MainActor
@Suite("FlowNodesManager Tests")
struct FlowNodesManagerTests {
    @Test func updateParentAndChildren() {
        let store = AssociatedObjectFlowInstanceAttachmentStore()
        let parentVC = UIViewController()
        let childVC = UIViewController()
        
        let parentCoordinator = NSObject()
        let childCoordinator = NSObject()
        
        let parentManager = FlowNodesManager(coordinator: parentCoordinator, attachmentStore: store)
        parentManager.setRootViewController(parentVC)
        
        let childManager = FlowNodesManager(coordinator: childCoordinator, attachmentStore: store)
        childManager.setRootViewController(childVC)
        
        // Связываем родителя
        childManager.updateParentViewController(parentVC)
        #expect(childManager.node.parent === parentManager.node)
        #expect(parentManager.node.children.contains { $0 === childManager.node })
        
        // Обновляем детей
        parentManager.updateChildViewControllers([childVC])
        #expect(parentManager.node.children.contains { $0 === childManager.node })
        
        // Убираем ребенка
        parentManager.updateChildViewControllers([])
        #expect(!parentManager.node.children.contains { $0 === childManager.node })
    }
}

@MainActor
@Suite("StackRouter Tests")
struct StackRouterTests {
    @Test func stackRouterNavigation() {
        let store = AssociatedObjectFlowInstanceAttachmentStore()
        let coordinator = NSObject()
        let manager = FlowNodesManager(coordinator: coordinator, attachmentStore: store)
        
        let nav = UINavigationController()
        let router = StackRouter(makeNavigationController: { nav }, nodesManager: manager)
        manager.setRootViewController(nav)
        
        let item1 = RouterItem(UIViewController())
        let item2 = RouterItem(UIViewController())
        
        router.setRoot(item1, animated: false)
        #expect(router.items.count == 1)
        #expect(router.items.first?.viewController === item1.viewController)
        
        router.push(item2, animated: false, completion: nil)
        #expect(router.items.count == 2)
        #expect(router.items.last?.viewController === item2.viewController)
        
        router.pop(animated: false, completion: nil)
        #expect(router.items.count == 1)
        #expect(router.items.first?.viewController === item1.viewController)
    }
}

@MainActor
@Suite("InlineRouter Tests")
struct InlineRouterTests {
    @Test func inlineRouterNavigation() {
        let store = AssociatedObjectFlowInstanceAttachmentStore()
        let coordinator = NSObject()
        let manager = FlowNodesManager(coordinator: coordinator, attachmentStore: store)
        
        let nav = UINavigationController()
        let router = InlineRouter(nodesManager: manager)
        
        let item1 = RouterItem(UIViewController())
        let item2 = RouterItem(UIViewController())
        
        // Встраиваем в навигейшн
        nav.setViewControllers([item1.viewController], animated: false)
        router.updateRootViewController(item1.viewController)
        manager.setRootViewController(item1.viewController)
        
        #expect(router.items.count == 1)
        #expect(router.items.first?.viewController === item1.viewController)
        
        router.push(item2, animated: false, completion: nil)
        #expect(router.items.count == 2)
        
        router.pop(animated: false, completion: nil)
        #expect(router.items.count == 1)
    }
}

@MainActor
@Suite("TabsRouter Tests")
struct TabsRouterTests {
    @Test func tabsRouterNavigation() {
        let store = AssociatedObjectFlowInstanceAttachmentStore()
        let coordinator = NSObject()
        let manager = FlowNodesManager(coordinator: coordinator, attachmentStore: store)
        
        let tabController = UITabBarController()
        let router = TabsRouter(makeTabBarController: { tabController }, nodesManager: manager)
        
        let item1 = RouterItem(UIViewController())
        let item2 = RouterItem(UIViewController())
        
        router.setItems([item1, item2], animated: false)
        #expect(tabController.viewControllers?.count == 2)
        #expect(router.selectedIndex == 0)
        
        router.selectTab(at: 1)
        #expect(router.selectedIndex == 1)
    }
}

@MainActor
@Suite("SwitchRouter Tests")
struct SwitchRouterTests {
    @Test func switchRouterNavigation() {
        let store = AssociatedObjectFlowInstanceAttachmentStore()
        let coordinator = NSObject()
        let manager = FlowNodesManager(coordinator: coordinator, attachmentStore: store)
        
        let router = SwitchRouter(nodesManager: manager)
        
        let item1 = RouterItem(UIViewController())
        let item2 = RouterItem(UIViewController())
        
        router.switchTo(item1, animated: false, completion: nil)
        #expect(router.currentItem?.viewController === item1.viewController)
        
        router.switchTo(item2, animated: false, completion: nil)
        #expect(router.currentItem?.viewController === item2.viewController)
    }
}

@MainActor
@Suite("FlowBuilder Tests")
struct FlowBuilderTests {
    @Test func buildStackFlow() {
        let composer = TestComposer()
        let flow = FlowBuilder.stack(composer: composer) { router, composer in
            TestStackCoordinator(router: router, composer: composer)
        }
        
        #expect(flow.viewController is UINavigationController)
        #expect(type(of: flow.coordinator) == TestStackCoordinator.self)
        #expect((flow.viewController as? UINavigationController)?.viewControllers.first === composer.rootVC)
    }
}
