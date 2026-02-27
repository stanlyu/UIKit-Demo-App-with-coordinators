//
//  HomeDependencies.swift
//  HomeFeature
//
//  Created by Любченко Станислав Валерьевич on 27.02.2026.
//

import UIKit

@MainActor
public protocol HomeExternalModulesFactory: AnyObject {
    func makePickupPointsViewController(onClose: @escaping () -> Void) -> UIViewController
}

public struct HomeDependencies {
    public private(set) weak var externalModulesFactory: (any HomeExternalModulesFactory)?

    public init(externalModulesFactory: any HomeExternalModulesFactory) {
        self.externalModulesFactory = externalModulesFactory
    }
}
