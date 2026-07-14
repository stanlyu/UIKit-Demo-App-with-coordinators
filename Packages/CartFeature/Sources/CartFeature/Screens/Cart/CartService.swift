//
//  CartService.swift
//  CartFeature
//
//  Created by Любченко Станислав Валерьевич on 22.12.2025.
//

protocol CartServicing: Sendable {
    @concurrent func fetchCartData() async
}

struct CartService: CartServicing {
    @concurrent func fetchCartData() async {
        // Эмитируем загрузку данных
        try? await Task.sleep(nanoseconds: 10_000_000)
    }
}
