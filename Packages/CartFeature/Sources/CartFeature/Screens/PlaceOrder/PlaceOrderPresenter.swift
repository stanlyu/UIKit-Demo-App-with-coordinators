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
        case onContinueToPayment
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
        view?.setOrderIDSubtitle("\(interactor.orderID)")
        updatePickupPoint(interactor.selectedPickupPoint)
        interactor.subscribeToSelectedPickupPointChanges { [weak self] pickupPoint in
            self?.updatePickupPoint(pickupPoint)
        }
    }

    func backButtonDidTap() {
        onEvent(.onBackTap)
    }
    
    func changePickupPointButtonDidTap() {
        onEvent(.onChangePickupPointTap)
    }
    
    func continueButtonDidTap() {
        onEvent(.onContinueToPayment)
    }
}

@MainActor
private extension PlaceOrderPresenter {
    func updatePickupPoint(_ pickupPoint: CartPickupPoint?) {
        guard let pickupPoint else {
            view?.setPickupPointText("ПВЗ: не выбран")
            return
        }

        view?.setPickupPointText("ПВЗ: \(pickupPoint.name)")
    }
}
