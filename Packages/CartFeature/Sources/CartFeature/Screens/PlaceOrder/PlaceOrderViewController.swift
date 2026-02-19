//
//  PlaceOrderViewController.swift
//  CartFeature
//
//  Created by Любченко Станислав Валерьевич on 22.12.2025.
//

import UIKit
import Core

@MainActor
protocol PlaceOrderView: AnyObject {
    func startLoading()
    func stopLoading()
    func setOrderIDSubtitle(_ subtitle: String)
    func setPickupPointText(_ text: String)
}

final class PlaceOrderViewController: UIViewController {

    var viewOutput: PlaceOrderViewOutput?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemOrange
        title = "Оформление заказа"
        loadingIndicator.layout(in: view)
        setupContinueButton()
        setupOrderIDLabel()
        setupPickupPointLabel()

        let action = UIAction { [unowned self] _ in
            self.viewOutput?.changePickupPointButtonDidTap()
        }

        if #available(iOS 16.0, *) {
            navigationItem.backAction = UIAction { [weak self] _ in
                self?.viewOutput?.backButtonDidTap()
            }
        } else {
            let backButton = UIBarButtonItem(
                    image: UIImage(systemName: "chevron.left"),
                    style: .plain,
                    target: self,
                    action: #selector(handleBackButtonTap)
                )

                navigationItem.leftBarButtonItem = backButton
                navigationController?.interactivePopGestureRecognizer?.delegate = self
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Смена ПВЗ", primaryAction: action)
        viewOutput?.viewDidLoad()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        continueButton.layer.cornerRadius = continueButton.bounds.height * 0.25
    }

    // MARK: - Private properties
    private lazy var loadingIndicator: LoadingView = LoadingView {
        continueButton
    }

    private lazy var continueButton: UIButton = {
        let button = UIButton.styledButton(
            title: "Продолжить",
            backgroundColor: .systemPink
        ) { [weak self] in
            self?.viewOutput?.continueButtonDidTap()
        }
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var orderIDLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var pickupPointLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .label
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Private methods

    private func setupContinueButton() {
        view.addSubview(continueButton)

        NSLayoutConstraint.activate([
            continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            continueButton.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setupOrderIDLabel() {
        view.addSubview(orderIDLabel)

        NSLayoutConstraint.activate([
            orderIDLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            orderIDLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8)
        ])
    }

    private func setupPickupPointLabel() {
        view.addSubview(pickupPointLabel)

        NSLayoutConstraint.activate([
            pickupPointLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            pickupPointLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            pickupPointLabel.topAnchor.constraint(equalTo: orderIDLabel.bottomAnchor, constant: 8)
        ])
    }

    @objc private func handleBackButtonTap() {
        viewOutput?.backButtonDidTap()
    }
}

extension PlaceOrderViewController: PlaceOrderView {
    func startLoading() {
        loadingIndicator.startLoading()
        deactivateNavigationRightBarButton()
    }

    func stopLoading() {
        loadingIndicator.stopLoading()
        activateNavigationRightBarButton()
    }

    func setOrderIDSubtitle(_ subtitle: String) {
        orderIDLabel.text = subtitle
        orderIDLabel.alpha = subtitle.isEmpty ? 0.0 : 1.0
    }

    func setPickupPointText(_ text: String) {
        pickupPointLabel.text = text
    }
}

extension PlaceOrderViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return true
    }
}
