//
//  PickupPointsPresenter.swift
//  DeliveryFeature
//
//  Created by Любченко Станислав Валерьевич on 22.12.2025.
//

import Foundation

enum PickupPointsSectionKind: Hashable {
    case active
    case favorites
}

struct PickupPointsSection: Hashable {
    let kind: PickupPointsSectionKind
    let title: String
    let rows: [PickupPointsRow]
}

enum PickupPointsRow: Hashable {
    enum ID: Hashable {
        case active
        case activePlaceholder
        case favorite(Int)
        case favoritePlaceholder
    }

    case active(title: String, subtitle: String)
    case activePlaceholder(title: String, subtitle: String)
    case favorite(id: Int, title: String, selected: Bool)
    case favoritePlaceholder(text: String)

    var id: ID {
        switch self {
        case .active:
            return .active
        case .activePlaceholder:
            return .activePlaceholder
        case let .favorite(id, _, _):
            return .favorite(id)
        case .favoritePlaceholder:
            return .favoritePlaceholder
        }
    }
}

struct PickupPointsViewState {
    let sections: [PickupPointsSection]
    let isConfirmButtonEnabled: Bool
}

@MainActor
protocol PickupPointsInput: AnyObject {
    func confirmDeleteFavoritePickupPoint(_ pickupPoint: PickupPoint)
}

@MainActor
protocol PickupPointsView: AnyObject {
    func render(_ state: PickupPointsViewState)
}

@MainActor
protocol PickupPointsViewOutput: AnyObject {
    func viewDidLoad()
    func addButtonDidTap()
    func favoritePickupPointDidTap(_ row: PickupPointsRow)
    func confirmSelectionButtonDidTap()
    func favoriteDeleteButtonDidTap(_ row: PickupPointsRow)
}

@MainActor
final class PickupPointsPresenter {
    enum Event {
        case onAddPickupPoint
        case onFavoriteDeleteRequested(pickupPoint: PickupPoint, input: PickupPointsInput)
    }

    weak var view: PickupPointsView?

    init(interactor: PickupPointsInteracting, onEvent: @escaping (Event) -> Void) {
        self.interactor = interactor
        self.onEvent = onEvent
    }

    // MARK: - Private members

    private let interactor: PickupPointsInteracting
    private let onEvent: (Event) -> Void

    private func makeViewState(from state: PickupPointsState) -> PickupPointsViewState {
        let activeRow: PickupPointsRow
        if let active = state.activePickupPoint {
            activeRow = .active(
                title: active.name,
                subtitle: "Текущий ПВЗ для оформления заказов"
            )
        } else {
            activeRow = .activePlaceholder(
                title: "Активный ПВЗ не выбран",
                subtitle: "Выберите ПВЗ из списка избранных ниже"
            )
        }

        let favoriteRows: [PickupPointsRow]
        if state.favoritePickupPoints.isEmpty {
            favoriteRows = [.favoritePlaceholder(text: "Избранных ПВЗ пока нет. Нажмите «Добавить».")]
        } else {
            favoriteRows = state.favoritePickupPoints.map { pickupPoint in
                .favorite(
                    id: pickupPoint.id,
                    title: pickupPoint.name,
                    selected: state.selectedFavoritePickupPointID == pickupPoint.id
                )
            }
        }

        return PickupPointsViewState(
            sections: [
                PickupPointsSection(kind: .active, title: "Активный ПВЗ", rows: [activeRow]),
                PickupPointsSection(kind: .favorites, title: "Избранные ПВЗ", rows: favoriteRows)
            ],
            isConfirmButtonEnabled: state.canConfirmSelection
        )
    }

    private func pickupPoint(for row: PickupPointsRow) -> PickupPoint? {
        guard case let .favorite(id, title, _) = row else { return nil }
        return PickupPoint(id: id, name: title)
    }
}

extension PickupPointsPresenter: PickupPointsViewOutput {
    func viewDidLoad() {
        interactor.subscribeToStateChanges { [weak self] state in
            guard let self else { return }
            let viewState = makeViewState(from: state)
            view?.render(viewState)
        }

        interactor.activate()
    }

    func addButtonDidTap() {
        onEvent(.onAddPickupPoint)
    }

    func favoritePickupPointDidTap(_ row: PickupPointsRow) {
        guard let pickupPoint = pickupPoint(for: row) else { return }
        interactor.selectFavoritePickupPoint(id: pickupPoint.id)
    }

    func confirmSelectionButtonDidTap() {
        interactor.confirmSelectedPickupPoint()
    }

    func favoriteDeleteButtonDidTap(_ row: PickupPointsRow) {
        guard let pickupPoint = pickupPoint(for: row) else { return }
        onEvent(.onFavoriteDeleteRequested(pickupPoint: pickupPoint, input: self))
    }
}

extension PickupPointsPresenter: PickupPointsInput {
    func confirmDeleteFavoritePickupPoint(_ pickupPoint: PickupPoint) {
        interactor.removeFromFavorites(pickupPointID: pickupPoint.id)
    }
}
