//
//  LoadingView.swift
//  Core
//
//  Created by Любченко Станислав Валерьевич on 22.12.2025.
//

import UIKit

public final class LoadingView: UIView {

    public init(contentProvider: () -> UIView) {
        super.init(frame: .zero)
        content = contentProvider()
        addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func startLoading() {
        loadingIndicator.startAnimating()
        UIView.animate(withDuration: 0.25) {
            self.loadingIndicator.alpha = 1.0
            self.content.alpha = 0.0
        }
    }

    public func stopLoading() {
        UIView.animate(withDuration: 0.25) {
            self.loadingIndicator.alpha = 0.0
            self.content.alpha = 1.0
        } completion: { _ in
            self.loadingIndicator.stopAnimating()
        }
    }

    public func layout(in containerView: UIView) {
        containerView.addSubview(loadingIndicator)
        self.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
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
    private var content: UIView!
}
