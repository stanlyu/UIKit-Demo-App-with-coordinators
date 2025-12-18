//
//  HomeInterfaces.swift
//  Demo App With Coordinators
//
//  Created by Любченко Станислав Валерьевич on 18.12.2025.
//

import UIKit

public enum HomeScreenEvent {
    case placeOrder(Int)
}

public func homeViewController(with eventHandler: (HomeScreenEvent) -> Void) -> UIViewController {
    #warning("TODO: Implement homeViewController in HomeInterfaces")
    return UIViewController()
}
