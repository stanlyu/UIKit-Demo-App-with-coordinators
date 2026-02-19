//
//  PlaceOrderInteractor.swift
//  CartFeature
//
//  Created by Любченко Станислав Валерьевич on 22.12.2025.
//

@MainActor
protocol PlaceOrderInteracting: AnyObject {
    var orderID: Int { get }
    var selectedPickupPoint: CartPickupPoint? { get }

    func subscribeToSelectedPickupPointChanges(_ listener: @escaping (CartPickupPoint) -> Void)
    func placeOrder(completion: @escaping () -> Void)
}

@MainActor
final class PlaceOrderInteractor {

    let orderID: Int
    var selectedPickupPoint: CartPickupPoint? {
        selectedPickupPointProvider.selectedPickupPoint
    }

    init(
        orderID: Int,
        service: PlaceOrderServicing,
        selectedPickupPointProvider: CartSelectedPickupPointProviding
    ) {
        self.orderID = orderID
        self.service = service
        self.selectedPickupPointProvider = selectedPickupPointProvider
    }

    // MARK: - Private properties

    private let service: PlaceOrderServicing
    private let selectedPickupPointProvider: CartSelectedPickupPointProviding
}

extension PlaceOrderInteractor: PlaceOrderInteracting {
    func subscribeToSelectedPickupPointChanges(_ listener: @escaping (CartPickupPoint) -> Void) {
        selectedPickupPointProvider.subscribeToSelectedPickupPointChanges(listener)
    }

    func placeOrder(completion: @escaping () -> Void) {
        Task {
            await self.service.placeOrder(orderID: orderID)
            completion()
        }
    }
}
