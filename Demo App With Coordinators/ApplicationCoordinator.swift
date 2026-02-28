import UIKit
import Core

typealias ApplicationCoordinator = ApplicationCoordinatingLogic<SwitchRouter>

final class ApplicationCoordinatingLogic<Router: SwitchRouting>: Coordinator<Router, ApplicationRoute> {

    init<C: ApplicationComposing>(composer: C) {
        super.init(composer: composer)
    }

    override func start(_ capability: StartCapability) {
        let item = composer.makeItem(for: .launch(eventHandler: { [unowned self] event in
            self.handleLaunchEvent(event)
        }))
        router?.setRoot(item, animated: false, completion: nil)
    }

    private func handleLaunchEvent(_ event: LaunchScreenEvent) {
        switch event {
        case .mainFlowStarted:
            let item = composer.makeItem(for: .mainFlow)
            router?.setRoot(item, animated: true, completion: nil)
        }
    }
}
