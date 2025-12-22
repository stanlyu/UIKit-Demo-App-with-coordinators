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
        view.backgroundColor = .systemMint
        loadingIndicator.layout(in: view)
        setupOrderButton()
        viewOutput?.viewDidLoad()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Установка скругления - 25% от высоты кнопки
        orderButton.layer.cornerRadius = orderButton.bounds.height * 0.25
    }

    // MARK: - Private properties
    private lazy var loadingIndicator: LoadingView = LoadingView {
        orderButton
    }
    private lazy var orderButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Оформить заказ", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        button.setTitleColor(.label, for: .normal)
        
        // Конфигурация для отступов
        var configuration = UIButton.Configuration.plain()
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)
        button.configuration = configuration
        
        // Настройка внешнего вида
        button.backgroundColor = .systemBlue
        button.tintColor = .white
        
        // Добавление тени
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 0)
        button.layer.shadowRadius = 7
        button.layer.shadowOpacity = 0.5

        button.addTarget(self, action: #selector(orderButtonTapped), for: .touchUpInside)
        button.alpha = 0.0
        return button
    }()

    // MARK: - Private methods

    private func setupOrderButton() {
        view.addSubview(orderButton)
        
        NSLayoutConstraint.activate([
            orderButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            orderButton.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    @objc private func orderButtonTapped() {
        viewOutput?.orderButtonTapped()
    }
}

extension HomeViewController: HomeView {
    func startLoading() {
        loadingIndicator.startLoading()
    }

    func stopLoading() {
        loadingIndicator.stopLoading()
    }
}
