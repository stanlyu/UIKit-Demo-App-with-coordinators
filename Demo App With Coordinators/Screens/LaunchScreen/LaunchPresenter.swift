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
    weak var view: LaunchView?

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
        print("[LaunchPresenter] viewDidLoad called")
        view?.startAnimation()
        interactor.fetchData { [weak self] in
            print("[LaunchPresenter] interactor.fetchData completed")
            self?.view?.stopAnimation()
            self?.onEvent(.mainFlowStarted)
        }
    }
}
