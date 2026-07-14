import UIKit

extension FlowRouter where RootViewController == UINavigationController, Driver == StackNavigationDriver {
    internal convenience init(
        makeNavigationController: @MainActor () -> UINavigationController,
        attachmentManager: any FlowInstanceAttachmentStoring
    ) {
        let navigationController = makeNavigationController()
        let delegateDispatcher = NavigationControllerDelegateDispatcher.install(on: navigationController)
        let driver = StackNavigationDriver(
            navigationController: navigationController,
            delegateDispatcher: delegateDispatcher
        )
        self.init(
            rootViewController: navigationController,
            driver: driver,
            attachmentStore: attachmentManager
        )
        driver.onExternalMutation = { [weak self] mutation in
            self?.applyInstanceMutation(mutation)
        }
    }
}

extension FlowRouter where RootViewController == UINavigationController, Driver == StackNavigationDriver {
    var items: [RouterItem] {
        driver.viewControllers.map { RouterItem($0) }
    }

    func setRoot(_ item: RouterItem, animated: Bool) {
        driver.setRoot(item, animated: animated) { [weak self] mutation in
            self?.applyInstanceMutation(mutation)
        }
    }

    func push(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        driver.push(item, animated: animated) { [weak self] mutation in
            self?.applyInstanceMutation(mutation)
            completion?()
        }
    }

    func pop(animated: Bool, completion: (() -> Void)?) {
        driver.pop(animated: animated) { [weak self] mutation in
            self?.applyInstanceMutation(mutation)
            completion?()
        }
    }

    func popToRoot(animated: Bool, completion: (() -> Void)?) {
        driver.popToRoot(animated: animated) { [weak self] mutation in
            self?.applyInstanceMutation(mutation)
            completion?()
        }
    }

    func popTo(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        driver.popTo(item, animated: animated) { [weak self] mutation in
            self?.applyInstanceMutation(mutation)
            completion?()
        }
    }

    func setStack(_ items: [RouterItem], animated: Bool) {
        driver.setStack(items, animated: animated) { [weak self] mutation in
            self?.applyInstanceMutation(mutation)
        }
    }
}

@MainActor
internal final class StackNavigationFacade {
    internal init(router: FlowRouter<UINavigationController, StackNavigationDriver>) {
        self.router = router
    }

    private let router: FlowRouter<UINavigationController, StackNavigationDriver>
}

extension StackNavigationFacade: StackNavigation {
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
