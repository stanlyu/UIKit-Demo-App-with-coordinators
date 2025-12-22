//
//  CartInteractor.swift
//  CartFeature
//
//  Created by Любченко Станислав Валерьевич on 22.12.2025.
//

@MainActor
protocol CartInteracting: AnyObject {
    var orderID: Int { get }
    func fetchData(completion: @escaping () -> Void)
}

final class CartInteractor {

    init(service: CartServicing) {
        self.service = service
    }

    // MARK: - Private properties

    private let service: CartServicing
}

extension CartInteractor: CartInteracting {

    var orderID: Int {
        return Int.random(in: 1...1_000_000)
    }
    
    func fetchData(completion: @escaping () -> Void) {
        Task {
            await service.fetchCartData()
            completion()
        }
    }
}
