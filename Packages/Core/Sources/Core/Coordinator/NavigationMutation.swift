import UIKit

/// Описание изменений UIKit-навигации, которые нужно отразить в дереве `FlowInstance`.
@MainActor
struct NavigationMutation {
    let insertedItems: [RouterItem]
    let removedViewControllers: [UIViewController]

    init(
        insertedItems: [RouterItem] = [],
        removedViewControllers: [UIViewController] = []
    ) {
        self.insertedItems = insertedItems
        self.removedViewControllers = removedViewControllers
    }

    var isEmpty: Bool {
        insertedItems.isEmpty && removedViewControllers.isEmpty
    }

    static func stackDelta(
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

    static func externalStackDelta(
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
