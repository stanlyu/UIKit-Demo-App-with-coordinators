//
//  HomeViewController.swift
//  HomeFeature
//
//  Created by Любченко Станислав Валерьевич on 19.12.2025.
//

import UIKit
import Core

@MainActor
protocol HomeView: AnyObject {
    func startLoading()
    func stopLoading()
}

final class HomeViewController: UIViewController {

    var viewOutput: HomeViewOutput?

    override func viewDidLoad() {
        super.viewDidLoad()
        print("[HomeViewController] viewDidLoad called")
        view.backgroundColor = .systemMint
        loadingIndicator.layout(in: view)
        setupOrderButton()
        title = "Главная"

        let action = UIAction { [unowned self] _ in
            print("[HomeViewController] ПВЗ button action triggered")
            self.viewOutput?.pickupPointButtonDidTap()
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "ПВЗ", primaryAction: action)
        viewOutput?.viewDidLoad()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        placeOrderButton.layer.cornerRadius = placeOrderButton.bounds.height * 0.25
    }

    // MARK: - Private properties
    private lazy var loadingIndicator: LoadingView = LoadingView {
        placeOrderButton
    }

    private lazy var placeOrderButton: UIButton = {
        let button = UIButton.styledButton(
            title: "Оформить заказ"
        ) { [weak self] in
            self?.viewOutput?.placeOrderButtonDidTap()
        }
        button.translatesAutoresizingMaskIntoConstraints = false
        button.alpha = 0
        return button
    }()

    // MARK: - Private methods

    private func setupOrderButton() {
        view.addSubview(placeOrderButton)

        NSLayoutConstraint.activate([
            placeOrderButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            placeOrderButton.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}

extension HomeViewController: HomeView {
    func startLoading() {
        loadingIndicator.startLoading()
        deactivateNavigationRightBarButton()
    }

    func stopLoading() {
        loadingIndicator.stopLoading()
        activateNavigationRightBarButton()
    }
}
