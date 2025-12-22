//
//  CartInterfaces.swift
//  Demo App With Coordinators
//
//  Created by Любченко Станислав Валерьевич on 18.12.2025.
//

import UIKit

@MainActor
public protocol CartInput {
    func placeOrder(_ orderID: Int)
}

public func cartViewController(with inputProvider: (CartInput) -> Void) -> UIViewController {
    #warning("TODO: Implement cartViewController in CartInterfaces")
    let cartCoordinator = CartCoordinator()
    inputProvider(cartCoordinator)
    return cartCoordinator
}
