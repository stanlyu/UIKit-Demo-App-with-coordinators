//
//  WeakCoordinator.swift
//  Core
//
//

import Foundation

@MainActor
final class WeakCoordinator {
    weak var ref: (any Coordinating)?
    
    init(_ c: any Coordinating) {
        self.ref = c
    }
}
