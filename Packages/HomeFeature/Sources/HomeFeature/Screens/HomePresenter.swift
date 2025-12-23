//
//  HomePresenter.swift
//  HomeFeature
//
//  Created by Любченко Станислав Валерьевич on 19.12.2025.
//

@MainActor
protocol HomeViewOutput: AnyObject {
    func viewDidLoad()
    func placeOrderButtonDidTap()
    func pickupPointButtonDidTap()
}

final class HomePresenter {
    enum Event {
        case onPickupPointTap
        case onPlaceOrderTap(Int)
    }

    weak var view: HomeView?

    init(interactor: HomeInteracting, onEvent: @escaping (Event) -> Void) {
        self.interactor = interactor
        self.onEvent = onEvent
    }

    // MARK: - Private properties

    private let interactor: HomeInteracting
    private let onEvent: (Event) -> Void
}

extension HomePresenter: HomeViewOutput {
    func viewDidLoad() {
        view?.startLoading()
        
        interactor.fetchData { [weak self] in
            self?.view?.stopLoading()
        }
    }

    func placeOrderButtonDidTap() {
        onEvent(.onPlaceOrderTap(interactor.orderID))
    }

    func pickupPointButtonDidTap() {
        onEvent(.onPickupPointTap)
    }
}
