//
//  HomeInterfaces.swift
//  Demo App With Coordinators
//
//  Created by Любченко Станислав Валерьевич on 18.12.2025.
//

import UIKit

@MainActor
public protocol HomeInput {
    func presentPickupPointsViewController(_ viewController: UIViewController)
}

public enum HomeEvent {
    case placeOrder(Int)
    case selectPickupPoint
}

@MainActor
public func homeViewController(with eventHandler: @escaping (HomeEvent) -> Void) -> UIViewController & HomeInput {
    let coordinator = HomeCoordinator(composer: HomeComposer(), eventHandler: eventHandler)
    coordinator.navigationBar.prefersLargeTitles = true
    return coordinator
}
