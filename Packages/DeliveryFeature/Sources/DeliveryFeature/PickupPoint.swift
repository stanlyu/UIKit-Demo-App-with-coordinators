//
//  PickupPoint.swift
//  DeliveryFeature
//
//  Created by Любченко Станислав Валерьевич on 16.02.2026.
//

import Foundation

public struct PickupPoint: Codable, Hashable, Sendable {
    public let id: Int
    public let name: String

    public init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}
