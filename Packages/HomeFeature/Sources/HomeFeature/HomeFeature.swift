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
    HomeCoordinator(composer: HomeComposer(), eventHandler: eventHandler)
}
