//
//  PlaceOrderService.swift
//  CartFeature
//
//  Created by Любченко Станислав Валерьевич on 22.12.2025.
//

protocol PlaceOrderServicing {
    @concurrent func placeOrder(orderID: Int) async
}

struct PlaceOrderService: PlaceOrderServicing {
    @concurrent func placeOrder(orderID: Int) async {
        // Эмитируем отправку данных
        try? await Task.sleep(nanoseconds: UInt64.random(in: 500_000_000...3_500_000_000))
    }
}
