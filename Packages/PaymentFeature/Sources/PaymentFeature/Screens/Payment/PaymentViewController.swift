//
//  PaymentViewController.swift
//  PaymentFeature
//
//  Created by Любченко Станислав Валерьевич on 19.02.2026.
//

import UIKit

@MainActor
final class PaymentViewController: UIViewController {
    init(viewOutput: PaymentViewOutput) {
        self.viewOutput = viewOutput
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemRed.withAlphaComponent(0.14)
        title = "Оплата"
        setupNavigationBar()

        setupLayout()
        viewOutput.viewDidLoad()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Возвращаем исходное состояние жеста назад, чтобы не блокировать другие экраны.
        if let previousInteractivePopGestureIsEnabled {
            navigationController?.interactivePopGestureRecognizer?.isEnabled = previousInteractivePopGestureIsEnabled
            self.previousInteractivePopGestureIsEnabled = nil
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        payButton.layer.cornerRadius = payButton.bounds.height * 0.25
    }

    // MARK: - Private members

    private let viewOutput: PaymentViewOutput
    private var previousInteractivePopGestureIsEnabled: Bool?
    private var isProcessingState = false
    private var spinnerLeadingToTitleConstraint: NSLayoutConstraint?

    private lazy var backBarButtonItem: UIBarButtonItem = {
        let item = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonDidTap)
        )
        return item
    }()

    private lazy var amountTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Сумма к оплате"
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var amountValueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 40, weight: .bold)
        label.textColor = .label
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var payButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .systemRed.withAlphaComponent(0.8)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 22, weight: .semibold)
        button.setTitle("Оплатить", for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 18, bottom: 10, right: 18)

        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 0)
        button.layer.shadowRadius = 7
        button.layer.shadowOpacity = 0.35

        button.addAction(UIAction { [weak self] _ in
            self?.viewOutput.payButtonDidTap()
        }, for: .touchUpInside)

        return button
    }()

    private lazy var payButtonActivityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.color = .white
        indicator.hidesWhenStopped = true
        indicator.alpha = 0
        return indicator
    }()

    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = backBarButtonItem
    }

    private func setupLayout() {
        view.addSubview(amountTitleLabel)
        view.addSubview(amountValueLabel)
        view.addSubview(payButton)
        payButton.addSubview(payButtonActivityIndicator)

        let spinnerAnchor = payButton.titleLabel?.trailingAnchor ?? payButton.centerXAnchor
        let spinnerLeadingToTitleConstraint = payButtonActivityIndicator.leadingAnchor.constraint(
            equalTo: spinnerAnchor,
            constant: 8
        )
        spinnerLeadingToTitleConstraint.isActive = false
        self.spinnerLeadingToTitleConstraint = spinnerLeadingToTitleConstraint

        NSLayoutConstraint.activate([
            amountTitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            amountTitleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -120),

            amountValueLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            amountValueLabel.topAnchor.constraint(equalTo: amountTitleLabel.bottomAnchor, constant: 12),

            payButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            payButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32),

            payButtonActivityIndicator.trailingAnchor.constraint(lessThanOrEqualTo: payButton.trailingAnchor, constant: -12),
            payButtonActivityIndicator.centerYAnchor.constraint(equalTo: payButton.centerYAnchor)
        ])
    }

    private func setBackNavigationEnabled(_ isEnabled: Bool) {
        if previousInteractivePopGestureIsEnabled == nil {
            previousInteractivePopGestureIsEnabled = navigationController?.interactivePopGestureRecognizer?.isEnabled ?? true
        }

        backBarButtonItem.isEnabled = isEnabled

        if isEnabled {
            navigationController?.interactivePopGestureRecognizer?.isEnabled = previousInteractivePopGestureIsEnabled ?? true
        } else {
            navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        }
    }

    @objc
    private func backButtonDidTap() {
        viewOutput.backButtonDidTap()
    }
}

extension PaymentViewController: PaymentView {
    func setAmountText(_ text: String) {
        amountValueLabel.text = text
    }

    func setProcessingState(isProcessing: Bool) {
        payButton.isEnabled = !isProcessing
        payButton.alpha = isProcessing ? 0.7 : 1.0
        setBackNavigationEnabled(!isProcessing)

        let shouldAnimate = isProcessingState != isProcessing
        isProcessingState = isProcessing

        spinnerLeadingToTitleConstraint?.isActive = isProcessing

        if isProcessing {
            payButtonActivityIndicator.startAnimating()
        }

        let updates = { [self] in
            payButton.titleLabel?.transform = isProcessing ? CGAffineTransform(translationX: -10, y: 0) : .identity
            payButtonActivityIndicator.alpha = isProcessing ? 1 : 0
            payButton.layoutIfNeeded()
        }

        if shouldAnimate {
            UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseInOut], animations: updates) { [weak self] _ in
                guard let self else { return }
                if isProcessing == false {
                    self.payButtonActivityIndicator.stopAnimating()
                }
            }
        } else {
            updates()
            if isProcessing == false {
                payButtonActivityIndicator.stopAnimating()
            }
        }
    }
}
