//
//  PlaceOrderPresenter.swift
//  CartFeature
//
//  Created by Любченко Станислав Валерьевич on 22.12.2025.
//

@MainActor
protocol PlaceOrderViewOutput: AnyObject {
    func viewDidLoad()
    func backButtonDidTap()
    func changePickupPointButtonDidTap()
    func continueButtonDidTap()
}

final class PlaceOrderPresenter {
    enum Event {
        case onBackTap
        case onChangePickupPointTap
        case onCompletion
    }

    weak var view: PlaceOrderView?

    init(interactor: PlaceOrderInteracting, onEvent: @escaping (PlaceOrderPresenter.Event) -> Void) {
        self.interactor = interactor
        self.onEvent = onEvent
    }

    // MARK: - private properties

    private let interactor: PlaceOrderInteracting
    private let onEvent: (PlaceOrderPresenter.Event) -> Void
}

extension PlaceOrderPresenter: PlaceOrderViewOutput {
    func viewDidLoad() {
        view?.setNavigationSubtitle("\(interactor.orderID)")
    }

    func backButtonDidTap() {
        onEvent(.onBackTap)
    }
    
    func changePickupPointButtonDidTap() {
        onEvent(.onChangePickupPointTap)
    }
    
    func continueButtonDidTap() {
        view?.startLoading()
        interactor.placeOrder { [weak self] in
            self?.view?.stopLoading()
            self?.onEvent(.onCompletion)
        }
    }
}
