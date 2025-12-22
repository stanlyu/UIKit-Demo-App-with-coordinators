//
//  PlaceOrderInteractor.swift
//  CartFeature
//
//  Created by Любченко Станислав Валерьевич on 22.12.2025.
//

@MainActor
protocol PlaceOrderInteracting: AnyObject {
    var orderID: Int { get }
    func placeOrder(completion: @escaping () -> Void)
}

final class PlaceOrderInteractor {

    let orderID: Int

    init(orderID: Int, service: PlaceOrderServicing) {
        self.orderID = orderID
        self.service = service
    }

    // MARK: - Private properties

    private let service: PlaceOrderServicing
}

extension PlaceOrderInteractor: PlaceOrderInteracting {
    func placeOrder(completion: @escaping () -> Void) {
        Task {
            await self.service.placeOrder(orderID: orderID)
            completion()
        }
    }
}
