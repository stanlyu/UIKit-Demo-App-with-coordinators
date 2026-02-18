//
//  AddPickupPointsPresenter.swift
//  DeliveryFeature
//
//  Created by Любченко Станислав Валерьевич on 22.12.2025.
//

import Foundation

struct AddPickupPointsItemViewState {
    let id: Int
    let title: String
    let isSelected: Bool
}

struct AddPickupPointsViewState {
    let items: [AddPickupPointsItemViewState]
    let isConfirmButtonEnabled: Bool
}

@MainActor
protocol AddPickupPointsView: AnyObject {
    func render(_ state: AddPickupPointsViewState)
}

@MainActor
protocol AddPickupPointsViewOutput: AnyObject {
    func viewDidLoad()
    func pickupPointDidTap(id: Int)
    func confirmButtonDidTap()
    func backButtonDidTap()
}

@MainActor
final class AddPickupPointsPresenter: AddPickupPointsViewOutput {
    enum Event {
        case onBackTap
    }

    weak var view: AddPickupPointsView?

    init(interactor: AddPickupPointsInteracting, onEvent: @escaping (Event) -> Void) {
        self.interactor = interactor
        self.onEvent = onEvent
    }

    func viewDidLoad() {
        interactor.subscribeToStateChanges { [weak self] state in
            guard let self else { return }
            view?.render(makeViewState(from: state))
        }

        interactor.activate()
    }

    func pickupPointDidTap(id: Int) {
        interactor.toggleSelection(pickupPointID: id)
    }

    func confirmButtonDidTap() {
        interactor.applyChanges()
    }

    func backButtonDidTap() {
        onEvent(.onBackTap)
    }

    // MARK: - Private properties

    private let interactor: AddPickupPointsInteracting
    private let onEvent: (Event) -> Void

    private func makeViewState(from state: AddPickupPointsState) -> AddPickupPointsViewState {
        let items = state.pickupPoints.map { pickupPoint in
            AddPickupPointsItemViewState(
                id: pickupPoint.id,
                title: pickupPoint.name,
                isSelected: state.selectedPickupPointIDs.contains(pickupPoint.id)
            )
        }

        return AddPickupPointsViewState(
            items: items,
            isConfirmButtonEnabled: state.canApplyChanges
        )
    }
}
