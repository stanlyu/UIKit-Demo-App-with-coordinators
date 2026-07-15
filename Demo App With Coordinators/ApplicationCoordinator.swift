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
        let item = composer.makeItem(for: .launch(eventHandler: { [weak self] event in
            self?.handleLaunchEvent(event)
        }))
        router.switchTo(item, animated: false, completion: nil)
    }

    private func handleLaunchEvent(_ event: LaunchScreenEvent) {
        switch event {
        case .mainFlowStarted:
            let item = composer.makeItem(for: .mainFlow)
            router.switchTo(item, animated: true, completion: nil)
        }
    }
}
