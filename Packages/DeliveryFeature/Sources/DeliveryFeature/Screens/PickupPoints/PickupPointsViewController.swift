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

    override var title: String? {
        didSet {
            navigationItem.title = title
        }
    }

    override var navigationItem: UINavigationItem {
        _navigationItem ?? super.navigationItem
    }

    func setup(navigationItem: UINavigationItem) {
        _navigationItem = navigationItem
    }

    // MARK: - Private properties
    private lazy var loadingIndicator: LoadingView = LoadingView { UIView() }
    private var _navigationItem: UINavigationItem?
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
