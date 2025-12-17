//
//  LaunchPresenter.swift
//  Demo App With Coordinators
//
//  Created by Любченко Станислав Валерьевич on 17.12.2025.
//

protocol LaunchViewOutput: AnyObject {
    func viewDidLoad()
}

final class LaunchPresenter {
    weak var view: LaunchViewInput?

    init(interactor: LaunchInteracting, onEvent: @escaping (LaunchScreenEvent) -> Void) {
        self.interactor = interactor
        self.onEvent = onEvent
    }

    // Private members

    private let interactor: LaunchInteracting
    private let onEvent: (LaunchScreenEvent) -> Void
}

extension LaunchPresenter: LaunchViewOutput {
    func viewDidLoad() {
        interactor.start { [unowned self] state in
            switch state {
            case .loaded:
                self.view?.stopAnimation()
                self.onEvent(.mainFlowStarted)
            case .loading:
                self.view?.startAnimation()
            }
        }
    }
}
