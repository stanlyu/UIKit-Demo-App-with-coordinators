//
//  CoordinatorLink.swift
//  Core
//
//

import UIKit

/// Internal. Тегирует VC координатором. Тег читается однократно (consume).
@MainActor
enum CoordinatorLink {
    private nonisolated(unsafe) static var key: UInt8 = 0

    static func tag(_ coordinator: any Coordinating, on vc: UIViewController) {
        let w = WeakCoordinator(coordinator)
        objc_setAssociatedObject(vc, &key, w, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    static func take(from vc: UIViewController) -> (any Coordinating)? {
        guard let w = objc_getAssociatedObject(vc, &key) as? WeakCoordinator else { return nil }
        objc_setAssociatedObject(vc, &key, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return w.ref
    }
}
