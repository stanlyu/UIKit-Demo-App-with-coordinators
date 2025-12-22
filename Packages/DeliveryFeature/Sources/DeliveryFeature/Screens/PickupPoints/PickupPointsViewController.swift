//
//  PickupPointsViewController.swift
//  DeliveryFeature
//
//  Created by Любченко Станислав Валерьевич on 22.12.2025.
//

import UIKit
import Core

@MainActor
protocol PickupPointsView: AnyObject {
    func startLoading()
    func stopLoading()
}

final class PickupPointsViewController: UIViewController {
    var viewOutput: PickupPointsViewOutput?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemYellow
        loadingIndicator.layout(in: view)
        title = "Выбор ПВЗ"
        let action = UIAction { [unowned self] _ in
            self.viewOutput?.addButtonDidTap()
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Добавить", primaryAction: action)
        viewOutput?.viewDidLoad()
    }

    // MARK: - Private properties
    private lazy var loadingIndicator: LoadingView = LoadingView { UIView() }
}

extension PickupPointsViewController: PickupPointsView {
    func startLoading() {
        loadingIndicator.startLoading()

        if #available(iOS 16.0, *) {
            navigationItem.rightBarButtonItem?.isHidden = true
        } else {
            navigationItem.rightBarButtonItem?.isEnabled = false
        }
    }
    
    func stopLoading() {
        loadingIndicator.stopLoading()

        if #available(iOS 16.0, *) {
            navigationItem.rightBarButtonItem?.isHidden = false
        } else {
            navigationItem.rightBarButtonItem?.isEnabled = true
        }
    }
}
