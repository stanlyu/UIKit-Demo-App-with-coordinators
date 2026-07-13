import UIKit

@MainActor
internal struct NavigationMutation {
    internal let insertedItems: [RouterItem]
    internal let removedViewControllers: [UIViewController]

    internal init(
        insertedItems: [RouterItem] = [],
        removedViewControllers: [UIViewController] = []
    ) {
        self.insertedItems = insertedItems
        self.removedViewControllers = removedViewControllers
    }

    internal var isEmpty: Bool {
        insertedItems.isEmpty && removedViewControllers.isEmpty
    }

    internal static func stackDelta(
        oldStack: [UIViewController],
        newStack: [UIViewController],
        newItems: [RouterItem]
    ) -> NavigationMutation {
        let oldIDs = Set(oldStack.map(ObjectIdentifier.init))
        let newIDs = Set(newStack.map(ObjectIdentifier.init))

        let insertedItems = newItems.filter { item in
            !oldIDs.contains(ObjectIdentifier(item.viewController))
        }
        let removedViewControllers = oldStack.filter { viewController in
            !newIDs.contains(ObjectIdentifier(viewController))
        }

        return NavigationMutation(
            insertedItems: insertedItems,
            removedViewControllers: removedViewControllers
        )
    }

    internal static func externalStackDelta(
        oldStack: [UIViewController],
        newStack: [UIViewController]
    ) -> NavigationMutation {
        let newIDs = Set(newStack.map(ObjectIdentifier.init))
        let removedViewControllers = oldStack.filter { viewController in
            !newIDs.contains(ObjectIdentifier(viewController))
        }

        return NavigationMutation(removedViewControllers: removedViewControllers)
    }
}
