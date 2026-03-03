//
//  ChildAdopting.swift
//  Core
//
//

import UIKit

/// Internal. Единственный метод — проверить VC на наличие тега и линковать координаторы.
@MainActor
protocol ChildAdopting: AnyObject {
    func adoptTaggedChild(from viewController: UIViewController)
}
