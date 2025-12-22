//
//  HomeInterfaces.swift
//  Demo App With Coordinators
//
//  Created by Любченко Станислав Валерьевич on 18.12.2025.
//

import UIKit

public enum HomeScreenEvent {
    case placeOrder(Int)
    case selectPickupPoint
}

@MainActor
public func homeViewController(with eventHandler: @escaping (HomeScreenEvent) -> Void) -> UIViewController {
    HomeCoordinator(composer: HomeComposer(), eventHandler: eventHandler)
}
