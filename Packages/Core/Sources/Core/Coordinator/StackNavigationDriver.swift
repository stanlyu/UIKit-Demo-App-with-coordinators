import UIKit

@MainActor
internal final class StackNavigationDriver: NSObject {
    internal init(
        navigationController: UINavigationController,
        delegateDispatcher: NavigationControllerDelegateDispatcher
    ) {
        self.navigationController = navigationController
        self.delegateDispatcher = delegateDispatcher
        self.lastKnownStack = Self.weakStack(from: navigationController.viewControllers)
        super.init()
        // Driver подписывается на didShow, чтобы заметить native back-swipe
        // и внешние setViewControllers, которые прошли мимо FlowRouter.
        delegateDispatcher.addDelegate(self, category: .instance)
    }

    internal var onExternalMutation: ((NavigationMutation) -> Void)?

    internal var viewControllers: [UIViewController] {
        navigationController.viewControllers
    }

    internal func setRoot(
        _ item: RouterItem,
        animated: Bool,
        completion: @escaping (NavigationMutation) -> Void
    ) {
        performProgrammaticOperation(
            insertedItems: [item],
            expectedStack: [item.viewController],
            animated: animated,
            completion: completion
        ) { navigationController, completion in
            navigationController.setViewControllers([item.viewController], animated: animated, completion: completion)
        }
    }

    internal func push(
        _ item: RouterItem,
        animated: Bool,
        completion: @escaping (NavigationMutation) -> Void
    ) {
        let shouldAnimate = navigationController.viewControllers.isEmpty ? false : animated
        let expectedStack = navigationController.viewControllers + [item.viewController]
        performProgrammaticOperation(
            insertedItems: [item],
            expectedStack: expectedStack,
            animated: shouldAnimate,
            completion: completion
        ) { navigationController, completion in
            navigationController.pushViewController(item.viewController, animated: shouldAnimate, completion: completion)
        }
    }

    internal func pop(animated: Bool, completion: @escaping (NavigationMutation) -> Void) {
        let oldStack = navigationController.viewControllers
        let expectedStack = oldStack.count > 1 ? Array(oldStack.dropLast()) : oldStack
        performProgrammaticOperation(
            expectedStack: expectedStack,
            animated: animated,
            completion: completion
        ) { navigationController, completion in
            navigationController.popViewController(animated: animated, completion: completion)
        }
    }

    internal func popToRoot(animated: Bool, completion: @escaping (NavigationMutation) -> Void) {
        let oldStack = navigationController.viewControllers
        let expectedStack = oldStack.first.map { [$0] } ?? []
        performProgrammaticOperation(
            expectedStack: expectedStack,
            animated: animated,
            completion: completion
        ) { navigationController, completion in
            navigationController.popToRootViewController(animated: animated, completion: completion)
        }
    }

    internal func popTo(
        _ item: RouterItem,
        animated: Bool,
        completion: @escaping (NavigationMutation) -> Void
    ) {
        let oldStack = navigationController.viewControllers
        let expectedStack: [UIViewController]
        if let targetIndex = oldStack.firstIndex(of: item.viewController) {
            expectedStack = Array(oldStack.prefix(through: targetIndex))
        } else {
            expectedStack = oldStack
        }
        performProgrammaticOperation(
            expectedStack: expectedStack,
            animated: animated,
            completion: completion
        ) { navigationController, completion in
            navigationController.popToViewController(item.viewController, animated: animated, completion: completion)
        }
    }

    internal func setStack(
        _ items: [RouterItem],
        animated: Bool,
        completion: @escaping (NavigationMutation) -> Void
    ) {
        let expectedStack = items.map(\.viewController)
        performProgrammaticOperation(
            insertedItems: items,
            expectedStack: expectedStack,
            animated: animated,
            completion: completion
        ) { navigationController, completion in
            navigationController.setViewControllers(items.map(\.viewController), animated: animated, completion: completion)
        }
    }

    private func performProgrammaticOperation(
        insertedItems: [RouterItem] = [],
        expectedStack: [UIViewController],
        animated: Bool,
        completion: @escaping (NavigationMutation) -> Void,
        _ operation: (UINavigationController, @escaping () -> Void) -> Void
    ) {
        let oldStack = navigationController.viewControllers
        let transaction = StackNavigationTransaction(
            oldStack: oldStack,
            insertedItems: insertedItems,
            expectedStack: expectedStack,
            completion: completion
        )
        activeProgrammaticTransaction = transaction

        operation(navigationController) {
            self.commit(transaction, finalStack: self.navigationController.viewControllers)
        }

        // Без анимации и при no-op UIKit завершает операцию синхронно.
        // Если completion уже закоммитил transaction, этот вызов ничего не сделает.
        if !animated || stacksEqual(oldStack, navigationController.viewControllers) {
            commit(transaction, finalStack: navigationController.viewControllers)
        }
    }

    private func commit(
        _ transaction: StackNavigationTransaction,
        finalStack: [UIViewController]
    ) {
        guard !transaction.isCommitted else { return }

        transaction.isCommitted = true
        if activeProgrammaticTransaction === transaction {
            activeProgrammaticTransaction = nil
        }

        lastKnownStack = Self.weakStack(from: finalStack)
        transaction.completion(transaction.mutation(finalStack: finalStack))
    }

    private func stackSignature(_ stack: [UIViewController]) -> [ObjectIdentifier] {
        stack.map(ObjectIdentifier.init)
    }

    private func stacksEqual(_ lhs: [UIViewController], _ rhs: [UIViewController]) -> Bool {
        stackSignature(lhs) == stackSignature(rhs)
    }

    private weak var navigationController: UINavigationController!
    // Держим dispatcher сильной ссылкой: UINavigationController.delegate weak.
    private let delegateDispatcher: NavigationControllerDelegateDispatcher
    private var lastKnownStack: [WeakViewController]
    private var activeProgrammaticTransaction: StackNavigationTransaction?
}

extension StackNavigationDriver: UINavigationControllerDelegate {
    internal func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        let currentStack = navigationController.viewControllers
        if let transaction = activeProgrammaticTransaction,
           transaction.matchesExpectedStack(currentStack) {
            // Programmatic операции коммитятся через transaction. Native/user back
            // доходит сюда без active transaction и считается external mutation.
            commit(transaction, finalStack: currentStack)
            return
        }

        let mutation = NavigationMutation.externalStackDelta(
            oldStack: lastKnownStack.compactMap(\.viewController),
            newStack: currentStack
        )
        lastKnownStack = Self.weakStack(from: currentStack)

        guard !mutation.isEmpty else { return }
        onExternalMutation?(mutation)
    }
}

private extension StackNavigationDriver {
    static func weakStack(from viewControllers: [UIViewController]) -> [WeakViewController] {
        viewControllers.map(WeakViewController.init)
    }
}

private final class WeakViewController {
    init(_ viewController: UIViewController) {
        self.viewController = viewController
    }

    weak var viewController: UIViewController?
}

@MainActor
private final class StackNavigationTransaction {
    init(
        oldStack: [UIViewController],
        insertedItems: [RouterItem],
        expectedStack: [UIViewController],
        completion: @escaping (NavigationMutation) -> Void
    ) {
        self.oldStack = oldStack
        self.insertedItems = insertedItems
        self.expectedStack = expectedStack
        self.completion = completion
    }

    func matchesExpectedStack(_ stack: [UIViewController]) -> Bool {
        stackSignature(stack) == stackSignature(expectedStack)
    }

    func mutation(finalStack: [UIViewController]) -> NavigationMutation {
        NavigationMutation.stackDelta(
            oldStack: oldStack,
            newStack: finalStack,
            newItems: insertedItems
        )
    }

    var isCommitted = false
    let completion: (NavigationMutation) -> Void

    private let oldStack: [UIViewController]
    private let insertedItems: [RouterItem]
    private let expectedStack: [UIViewController]

    private func stackSignature(_ stack: [UIViewController]) -> [ObjectIdentifier] {
        stack.map(ObjectIdentifier.init)
    }
}
