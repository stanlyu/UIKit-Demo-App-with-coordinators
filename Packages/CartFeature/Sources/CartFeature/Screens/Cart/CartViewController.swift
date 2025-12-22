//
//  CartViewController.swift
//  CartFeature
//
//  Created by Любченко Станислав Валерьевич on 22.12.2025.
//

import UIKit
import Core

@MainActor
protocol CartView: AnyObject {
    func startLoading()
    func stopLoading()
}

final class CartViewController: UIViewController {

    var viewOutput: CartViewOutput?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemOrange
        loadingIndicator.layout(in: view)
        setupOrderButton()
        title = "Корзина"
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
            title: "Оформить заказ",
            backgroundColor: .systemPurple
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

extension CartViewController: CartView {
    func startLoading() {
        loadingIndicator.startLoading()
        deactivateNavigationRightBarButton()
    }

    func stopLoading() {
        loadingIndicator.stopLoading()
        activateNavigationRightBarButton()
    }
}
