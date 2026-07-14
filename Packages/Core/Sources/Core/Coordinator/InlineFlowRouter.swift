import UIKit

extension FlowRouter where RootViewController == UIViewController, Driver == InlineNavigationDriver {
    internal convenience init(attachmentManager: any FlowInstanceAttachmentStoring) {
        self.init(
            driver: InlineNavigationDriver(),
            attachmentStore: attachmentManager
        )
    }
}

extension FlowRouter where RootViewController == UIViewController, Driver == InlineNavigationDriver {
    var items: [RouterItem] {
        driver.flowStack(startingAt: rootViewController).map { RouterItem($0) }
    }

    func setRoot(_ item: RouterItem, animated: Bool) {
        let result = driver.replaceRoot(with: item, currentRoot: rootViewController, animated: animated)
        updateRootViewController(result.newRoot)
        applyInstanceMutation(result.mutation)
    }

    func push(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        let newRoot = driver.push(item, from: rootViewController, animated: animated) { [weak self] mutation in
            self?.applyInstanceMutation(mutation)
            completion?()
        }
        if let newRoot {
            updateRootViewController(newRoot)
        }
    }

    func pop(animated: Bool, completion: (() -> Void)?) {
        guard driver.pop(from: rootViewController, animated: animated, completion: { [weak self] mutation in
            self?.applyInstanceMutation(mutation)
            completion?()
        }) else {
            return
        }
    }

    func popToRoot(animated: Bool, completion: (() -> Void)?) {
        guard driver.popToRoot(from: rootViewController, animated: animated, completion: { [weak self] mutation in
            self?.applyInstanceMutation(mutation)
            completion?()
        }) else {
            return
        }
    }

    func popTo(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        guard driver.popTo(item, from: rootViewController, animated: animated, completion: { [weak self] mutation in
            self?.applyInstanceMutation(mutation)
            completion?()
        }) else {
            return
        }
    }

    func setStack(_ items: [RouterItem], animated: Bool) {
        guard let result = driver.setStack(items, from: rootViewController, animated: animated) else { return }
        updateRootViewController(result.newRoot)
        applyInstanceMutation(result.mutation)
    }
}

@MainActor
internal final class InlineNavigationFacade {
    internal init(router: FlowRouter<UIViewController, InlineNavigationDriver>) {
        self.router = router
    }

    private let router: FlowRouter<UIViewController, InlineNavigationDriver>
}

extension InlineNavigationFacade: StackNavigation {
    var items: [RouterItem] {
        router.items
    }

    func present(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        router.present(item, animated: animated, completion: completion)
    }

    func dismiss(animated: Bool, completion: (() -> Void)?) {
        router.dismiss(animated: animated, completion: completion)
    }

    func setRoot(_ item: RouterItem, animated: Bool) {
        router.setRoot(item, animated: animated)
    }

    func push(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        router.push(item, animated: animated, completion: completion)
    }

    func pop(animated: Bool, completion: (() -> Void)?) {
        router.pop(animated: animated, completion: completion)
    }

    func popToRoot(animated: Bool, completion: (() -> Void)?) {
        router.popToRoot(animated: animated, completion: completion)
    }

    func popTo(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        router.popTo(item, animated: animated, completion: completion)
    }

    func setStack(_ items: [RouterItem], animated: Bool) {
        router.setStack(items, animated: animated)
    }
}
