import UIKit

@MainActor
internal final class StackNavigationDriver: NSObject {
    internal init(
        navigationController: UINavigationController,
        delegateDispatcher: NavigationControllerDelegateDispatcher
    ) {
        self.navigationController = navigationController
        self.delegateDispatcher = delegateDispatcher
        self.lastKnownStack = navigationController.viewControllers
        super.init()
        delegateDispatcher.addDelegate(self, category: .framework)
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
        performProgrammaticOperation(newItems: [item], completion: completion) { navigationController, completion in
            navigationController.setViewControllers([item.viewController], animated: animated, completion: completion)
        }
    }

    internal func push(
        _ item: RouterItem,
        animated: Bool,
        completion: @escaping (NavigationMutation) -> Void
    ) {
        performProgrammaticOperation(newItems: [item], completion: completion) { navigationController, completion in
            let shouldAnimate = navigationController.viewControllers.isEmpty ? false : animated
            navigationController.pushViewController(item.viewController, animated: shouldAnimate, completion: completion)
        }
    }

    internal func pop(animated: Bool, completion: @escaping (NavigationMutation) -> Void) {
        performProgrammaticOperation(completion: completion) { navigationController, completion in
            navigationController.popViewController(animated: animated, completion: completion)
        }
    }

    internal func popToRoot(animated: Bool, completion: @escaping (NavigationMutation) -> Void) {
        performProgrammaticOperation(completion: completion) { navigationController, completion in
            navigationController.popToRootViewController(animated: animated, completion: completion)
        }
    }

    internal func popTo(
        _ item: RouterItem,
        animated: Bool,
        completion: @escaping (NavigationMutation) -> Void
    ) {
        performProgrammaticOperation(completion: completion) { navigationController, completion in
            navigationController.popToViewController(item.viewController, animated: animated, completion: completion)
        }
    }

    internal func setStack(
        _ items: [RouterItem],
        animated: Bool,
        completion: @escaping (NavigationMutation) -> Void
    ) {
        performProgrammaticOperation(newItems: items, completion: completion) { navigationController, completion in
            navigationController.setViewControllers(items.map(\.viewController), animated: animated, completion: completion)
        }
    }

    private func performProgrammaticOperation(
        newItems: [RouterItem] = [],
        completion: @escaping (NavigationMutation) -> Void,
        _ operation: (UINavigationController, @escaping () -> Void) -> Void
    ) {
        pendingProgrammaticStacks.removeAll()

        let oldStack = navigationController.viewControllers
        var mutation: NavigationMutation?
        var didCompleteBeforeMutation = false

        operation(navigationController) {
            guard let completedMutation = mutation else {
                didCompleteBeforeMutation = true
                return
            }
            completion(completedMutation)
        }

        let newStack = navigationController.viewControllers

        if !stacksEqual(oldStack, newStack) {
            pendingProgrammaticStacks.append(stackSignature(newStack))
        }
        lastKnownStack = newStack

        let resolvedMutation = NavigationMutation.stackDelta(
            oldStack: oldStack,
            newStack: newStack,
            newItems: newItems
        )
        mutation = resolvedMutation

        if didCompleteBeforeMutation {
            completion(resolvedMutation)
        }
    }

    private func consumeProgrammaticStack(_ stack: [UIViewController]) -> Bool {
        let signature = stackSignature(stack)
        guard let index = pendingProgrammaticStacks.firstIndex(of: signature) else {
            return false
        }
        pendingProgrammaticStacks.remove(at: index)
        return true
    }

    private func stackSignature(_ stack: [UIViewController]) -> [ObjectIdentifier] {
        stack.map(ObjectIdentifier.init)
    }

    private func stacksEqual(_ lhs: [UIViewController], _ rhs: [UIViewController]) -> Bool {
        stackSignature(lhs) == stackSignature(rhs)
    }

    private weak var navigationController: UINavigationController!
    private let delegateDispatcher: NavigationControllerDelegateDispatcher
    private var lastKnownStack: [UIViewController]
    private var pendingProgrammaticStacks: [[ObjectIdentifier]] = []
}

extension StackNavigationDriver: UINavigationControllerDelegate {
    internal func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        let currentStack = navigationController.viewControllers
        guard !consumeProgrammaticStack(currentStack) else {
            lastKnownStack = currentStack
            return
        }

        let mutation = NavigationMutation.externalStackDelta(
            oldStack: lastKnownStack,
            newStack: currentStack
        )
        lastKnownStack = currentStack

        guard !mutation.isEmpty else { return }
        onExternalMutation?(mutation)
    }
}
