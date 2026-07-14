//
//  PlaceOrderService.swift
//  CartFeature
//
//  Created by Любченко Станислав Валерьевич on 22.12.2025.
//

protocol PlaceOrderServicing: Sendable {
    @concurrent func placeOrder(orderID: Int) async
}

struct PlaceOrderService: PlaceOrderServicing {
    @concurrent func placeOrder(orderID: Int) async {
        // Эмитируем отправку данных
        try? await Task.sleep(nanoseconds: 10_000_000)
    }
}
