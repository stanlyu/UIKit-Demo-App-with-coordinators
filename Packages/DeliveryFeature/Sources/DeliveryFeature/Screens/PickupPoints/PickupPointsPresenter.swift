//
//  PickupPointsPresenter.swift
//  DeliveryFeature
//
//  Created by Любченко Станислав Валерьевич on 22.12.2025.
//

@MainActor
protocol PickupPointsViewOutput: AnyObject {
    func viewDidLoad()
    func addButtonDidTap()
}

final class PickupPointsPresenter {
    enum Event {
        case onAddPickupPoint
    }

    weak var view: PickupPointsView?

    init(interactor: PickupPointsInteracting, onEvent: @escaping (Event) -> Void) {
        self.interactor = interactor
        self.onEvent = onEvent
    }

    // MARK: - Private properties

    private let interactor: PickupPointsInteracting
    private let onEvent: (Event) -> Void
}

extension PickupPointsPresenter: PickupPointsViewOutput {
    func viewDidLoad() {
        view?.startLoading()

        interactor.fetchData { [unowned self] in
            self.view?.stopLoading()
        }
    }

    func addButtonDidTap() {
        onEvent(.onAddPickupPoint)
    }
}
