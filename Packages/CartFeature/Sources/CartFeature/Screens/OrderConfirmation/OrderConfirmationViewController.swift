//
//  OrderConfirmationViewController.swift
//  CartFeature
//
//  Created by Любченко Станислав Валерьевич on 22.12.2025.
//

import UIKit
import Core

final class OrderConfirmationViewController: UIViewController {

    var viewOutput: OrderConfirmationViewOutput?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemOrange
        title = "Финиш"
        setupLayout()
        navigationItem.hidesBackButton = true

        viewOutput?.viewDidLoad()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        returnButton.layer.cornerRadius = returnButton.bounds.height * 0.25
    }

    // MARK: - Private properties

    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var returnButton: UIButton = {
        let button = UIButton.styledButton(
            title: "К началу",
            backgroundColor: .systemGreen
        ) { [weak self] in
            self?.viewOutput?.returnButtonDidTap()
        }
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - Private methods

    private func setupLayout() {
        view.addSubview(messageLabel)
        view.addSubview(returnButton)

        NSLayoutConstraint.activate([
            messageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            messageLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            returnButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            returnButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
}

extension OrderConfirmationViewController: OrderConfirmationView {
    func render(_ state: OrderConfirmationViewState) {
        messageLabel.text = state.message
        messageLabel.textColor = state.messageColor
    }
}
