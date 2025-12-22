//
//  HomeViewController.swift
//  HomeFeature
//
//  Created by Любченко Станислав Валерьевич on 19.12.2025.
//

import UIKit

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
        setupLoadingIndicator()
        setupOrderButton()
        viewOutput?.viewDidLoad()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Установка скругления - 25% от высоты кнопки
        orderButton.layer.cornerRadius = orderButton.bounds.height * 0.25
    }

    // MARK: - Private properties
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        indicator.color = .systemGray
        indicator.alpha = 0.0
        return indicator
    }()

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
    
    private func setupLoadingIndicator() {
        view.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setupOrderButton() {
        view.addSubview(orderButton)
        
        NSLayoutConstraint.activate([
            orderButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            orderButton.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func animateViews(isLoading: Bool, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.3) {
            self.orderButton.alpha = isLoading ? 0.0 : 1.0
            self.loadingIndicator.alpha = isLoading ? 1.0 : 0.0
        } completion: { _ in
            completion?()
        }
    }

    @objc private func orderButtonTapped() {
        viewOutput?.orderButtonTapped()
    }
}

extension HomeViewController: HomeView {
    func startLoading() {
        loadingIndicator.startAnimating()
        animateViews(isLoading: true)
    }

    func stopLoading() {
        animateViews(isLoading: false) { [weak self] in
            self?.loadingIndicator.stopAnimating()
        }
    }
}
