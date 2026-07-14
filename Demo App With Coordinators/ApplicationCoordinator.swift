import UIKit
import Core

typealias ApplicationCoordinator = ApplicationCoordinatingLogic

final class ApplicationCoordinatingLogic: BaseCoordinator<any SwitchNavigation, ApplicationRoute> {

    init<C: ApplicationComposing>(
        router: any SwitchNavigation,
        composer: C
    ) {
        super.init(router: router, composer: composer)
    }

    override func start(_ context: CoordinatorStartContext) {
        print("[ApplicationCoordinator] start called")
        let item = composer.makeItem(for: .launch(eventHandler: { [weak self] event in
            print("[ApplicationCoordinator] launch event received: \(event)")
            self?.handleLaunchEvent(event)
        }))
        router.switchTo(item, animated: false, completion: nil)
    }

    private func handleLaunchEvent(_ event: LaunchScreenEvent) {
        switch event {
        case .mainFlowStarted:
            print("[ApplicationCoordinator] mainFlowStarted -> switching to mainFlow")
            let item = composer.makeItem(for: .mainFlow)
            router.switchTo(item, animated: true, completion: nil)
        }
    }
}
