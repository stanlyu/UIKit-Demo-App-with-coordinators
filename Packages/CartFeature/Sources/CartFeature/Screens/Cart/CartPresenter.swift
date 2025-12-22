//
//  CartPresenter.swift
//  CartFeature
//
//  Created by Любченко Станислав Валерьевич on 22.12.2025.
//

@MainActor
protocol CartViewOutput: AnyObject {
    func viewDidLoad()
    func placeOrderButtonDidTap()
}

final class CartPresenter {
    enum Event {
        case onPlaceOrderTap(Int)
    }

    weak var view: CartView?

    init(interactor: CartInteracting, onEvent: @escaping (Event) -> Void) {
        self.interactor = interactor
        self.onEvent = onEvent
    }

    // MARK: - Private properties

    private let interactor: CartInteracting
    private let onEvent: (Event) -> Void
}

extension CartPresenter: CartViewOutput {
    func viewDidLoad() {
        view?.startLoading()
        interactor.fetchData { [unowned self] in
            self.view?.stopLoading()
        }
    }

    func placeOrderButtonDidTap() {
        onEvent(.onPlaceOrderTap(interactor.orderID))
    }
}
