import UIKit

extension FlowRouter where RootViewController == UIViewController, Driver == SwitchNavigationDriver {
    internal convenience init(attachmentManager: any FlowInstanceAttachmentStoring) {
        self.init(
            driver: SwitchNavigationDriver(),
            attachmentStore: attachmentManager
        )
    }
}

extension FlowRouter where RootViewController == UIViewController, Driver == SwitchNavigationDriver {
    var currentItem: RouterItem? {
        rootViewController.map { RouterItem($0) }
    }

    func switchTo(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        driver.switchTo(item, currentRoot: rootViewController, animated: animated) { [weak self] newRoot, mutation in
            self?.updateRootViewController(newRoot)
            self?.applyInstanceMutation(mutation)
        } completion: { [weak self] mutation in
            self?.applyInstanceMutation(mutation)
            completion?()
        }
    }
}

@MainActor
internal final class SwitchNavigationFacade {
    internal init(router: FlowRouter<UIViewController, SwitchNavigationDriver>) {
        self.router = router
    }

    internal func setSwitchTransitionHandler(_ handler: SwitchTransitionHandler?) {
        router.driver.setTransitionHandler(handler)
    }

    private let router: FlowRouter<UIViewController, SwitchNavigationDriver>
}

extension SwitchNavigationFacade: SwitchNavigation {
    var currentItem: RouterItem? {
        router.currentItem
    }

    func present(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        router.present(item, animated: animated, completion: completion)
    }

    func dismiss(animated: Bool, completion: (() -> Void)?) {
        router.dismiss(animated: animated, completion: completion)
    }

    func switchTo(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        router.switchTo(item, animated: animated, completion: completion)
    }
}
