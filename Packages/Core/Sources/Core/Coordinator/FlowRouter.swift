import UIKit

/// Общий router для flow: хранит root `UIViewController`, driver конкретной навигации
/// и синхронизирует дерево `FlowInstance` после навигационных изменений.
@MainActor
internal final class FlowRouter<RootViewController: UIViewController, Driver>: FlowInstanceRouter {
    internal init(
        rootViewController: RootViewController? = nil,
        driver: Driver,
        attachmentStore: any FlowInstanceAttachmentStoring
    ) {
        self.driver = driver
        self.attachmentStore = attachmentStore

        if let rootViewController {
            updateRootViewController(rootViewController)
        }
    }

    internal var rootViewController: RootViewController? {
        weakRootViewController ?? bootstrapRootRetainer
    }

    internal var onRootReplaced: (@MainActor (RootViewController) -> Void)?

    internal let driver: Driver

    internal func updateRootViewController(_ viewController: RootViewController) {
        let previousRoot = rootViewController
        weakRootViewController = viewController

        if isAwaitingInstanceAttach {
            bootstrapRootRetainer = viewController
        } else if previousRoot !== viewController {
            onRootReplaced?(viewController)
        }
    }

    internal func markInstanceAttachedAndReleaseBootstrapRoot() {
        bootstrapRootRetainer = nil
        isAwaitingInstanceAttach = false
    }

    internal func setInstance(_ instance: any FlowInstanceNode) {
        self.instance = instance
    }

    internal func viewControllers(for items: [RouterItem]) -> [UIViewController] {
        items.map(\.viewController)
    }

    /// Единая реализация модального presentation для всех flow-router-ов.
    internal func present(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        FlowPresentationDriver.present(
            item.viewController,
            from: requireRootViewController(),
            item: item,
            animated: animated
        ) { [weak self] mutation in
            self?.applyInstanceMutation(mutation)
            completion?()
        }
    }

    /// Единая реализация модального dismiss для всех flow-router-ов.
    internal func dismiss(animated: Bool, completion: (() -> Void)?) {
        FlowPresentationDriver.dismissPresentedContent(
            from: requireRootViewController(),
            animated: animated
        ) { [weak self] mutation in
            self?.applyInstanceMutation(mutation)
            completion?()
        }
    }

    internal func applyInstanceMutation(_ mutation: NavigationMutation) {
        guard let currentInstance = instance else { return }

        // Новые instances усыновляются через child-first lookup.
        // Удаляемые instances выбираются иначе: удалять можно только direct child
        // текущего FlowInstance, чтобы не detach-нуть вложенный instance на том же UIViewController.
        for item in mutation.insertedItems {
            guard let childInstance = instance(for: item) else { continue }
            currentInstance.adopt(childInstance)
        }

        for viewController in mutation.removedViewControllers {
            guard let childInstance = directChildInstance(attachedTo: viewController, parent: currentInstance) else {
                continue
            }
            currentInstance.removeChild(childInstance)
            attachmentStore.detach(childInstance, from: viewController)
        }
    }

    private func instance(for item: RouterItem) -> (any FlowInstanceNode)? {
        item.instance ?? attachmentStore.instance(attachedTo: item.viewController)
    }

    private func requireRootViewController() -> RootViewController {
        FlowPresentationDriver.requireRoot(
            rootViewController,
            message: "FlowRouter's root view controller was deallocated."
        )
    }

    private func directChildInstance(
        attachedTo viewController: UIViewController,
        parent: any FlowInstanceNode
    ) -> (any FlowInstanceNode)? {
        attachmentStore
            .instances(attachedTo: viewController)
            .first { candidate in
                candidate.parent === parent
            }
    }

    private let attachmentStore: any FlowInstanceAttachmentStoring
    private weak var weakRootViewController: RootViewController?
    // До первого attach держим root сильной ссылкой: weakRootViewController может обнулиться раньше, чем FlowInstance будет удержан через attachment store.
    private var bootstrapRootRetainer: RootViewController?
    private weak var instance: (any FlowInstanceNode)?
    private var isAwaitingInstanceAttach = true
}
