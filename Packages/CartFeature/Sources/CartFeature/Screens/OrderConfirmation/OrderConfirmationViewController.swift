//
//  OrderConfirmationViewController.swift
//  CartFeature
//
//  Created by Любченко Станислав Валерьевич on 22.12.2025.
//

import UIKit

final class OrderConfirmationViewController: UIViewController {

    var viewOutput: OrderConfirmationViewOutput?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemOrange
        title = "Финиш"
        setupReturnButton()
        navigationItem.hidesBackButton = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        returnButton.layer.cornerRadius = returnButton.bounds.height * 0.25
    }

    // MARK: - Private properties

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

    private func setupReturnButton() {
        view.addSubview(returnButton)

        NSLayoutConstraint.activate([
            returnButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            returnButton.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
