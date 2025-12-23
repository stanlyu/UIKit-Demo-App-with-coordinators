//
//  HomeInterfaces.swift
//  Demo App With Coordinators
//
//  Created by Любченко Станислав Валерьевич on 18.12.2025.
//

import UIKit

public enum HomeEvent {
    case placeOrder(Int)
    case selectPickupPoint
}

@MainActor
public func homeViewController(with eventHandler: @escaping (HomeEvent) -> Void) -> UIViewController {
    let coordinator = HomeCoordinator(composer: HomeComposer(), eventHandler: eventHandler)
    coordinator.navigationBar.prefersLargeTitles = true
    return coordinator
}
