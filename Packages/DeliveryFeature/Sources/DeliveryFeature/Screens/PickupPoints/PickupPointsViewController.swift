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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewOutput?.viewDidLoad()
    }

    // MARK: - Private properties
    private lazy var loadingIndicator: LoadingView = LoadingView { UIView() }
}

extension PickupPointsViewController: PickupPointsView {
    func startLoading() {
        loadingIndicator.startLoading()
        deactivateNavigationRightBarButton()
    }
    
    func stopLoading() {
        loadingIndicator.stopLoading()
        activateNavigationRightBarButton()
    }
}
