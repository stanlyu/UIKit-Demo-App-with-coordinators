//
//  CartService.swift
//  CartFeature
//
//  Created by Любченко Станислав Валерьевич on 22.12.2025.
//

protocol CartServicing {
    @concurrent func fetchCartData() async
}

struct CartService: CartServicing {
    @concurrent func fetchCartData() async {
        // Эмитируем загрузку данных
        try? await Task.sleep(nanoseconds: UInt64.random(in: 500_000_000...3_500_000_000))
    }
}
